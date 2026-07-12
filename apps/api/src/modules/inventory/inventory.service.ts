import { GoogleGenAI } from '@google/genai';
import {
  BadRequestException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { calculateItemPrice } from '@swarnbook/business-logic';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { resolveDateRange } from '../../common/date-range.util';
import {
  CreateInventoryDto,
  ImportInventoryDto,
  ImportInventoryRowDto,
  InventoryStatsQueryDto,
  UpdateInventoryDto,
} from './inventory.dto';

type OcrDraftRow = {
  itemName: string;
  tagNumber: string | null;
  huid: string | null;
  hallmarkNumber: string | null;
  metalType: string;
  karat: string | null;
  grossWeight: number | null;
  netWeight: number | null;
  quantity: number;
  warnings: string[];
};

type InventoryFilters = {
  status?: string;
  metalType?: string;
  search?: string;
  categoryId?: string;
  categoryName?: string;
  location?: string;
  dateFrom?: string;
  dateTo?: string;
};

type SoldProductsFilters = {
  search?: string;
  dateFrom?: string;
  dateTo?: string;
};

@Injectable()
export class InventoryService {
  private readonly geminiModel: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    this.geminiModel =
      this.config.get<string>('GEMINI_INVENTORY_MODEL') ??
      'gemini-2.5-flash-lite';
  }

  async findAll(tenantId: string, filters?: InventoryFilters) {
    return this.prisma.inventoryItem.findMany({
      where: this.buildInventoryWhere(tenantId, filters),
      include: { category: true, karigar: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(tenantId: string, id: string) {
    const item = await this.prisma.inventoryItem.findFirst({
      where: { id, tenantId, deletedAt: null },
      include: { category: true, karigar: true },
    });
    if (!item) throw new NotFoundException('Item not found');
    return item;
  }

  async create(tenantId: string, dto: CreateInventoryDto) {
    const categoryId = await this.resolveCategoryId(tenantId, dto);
    return this.prisma.inventoryItem.create({
      data: this.toInventoryCreateData(tenantId, { ...dto, categoryId }),
    });
  }

  async update(tenantId: string, id: string, dto: UpdateInventoryDto) {
    await this.findOne(tenantId, id);
    const categoryId = await this.resolveCategoryId(tenantId, dto);
    return this.prisma.inventoryItem.update({
      where: { id },
      data: {
        itemName: dto.itemName,
        barcode: dto.barcode,
        categoryId,
        metalType: dto.metalType,
        karat: dto.karat,
        stockType: dto.stockType,
        quantity: dto.stockType === 'bulk' ? (dto.quantity ?? 1) : 1,
        grossWeight: dto.grossWeight,
        netWeight: dto.netWeight,
        tagNumber: dto.tagNumber,
        purity: dto.purity,
        makingChargesPerGram: dto.makingChargesPerGram,
        makingChargesFixed: dto.makingChargesFixed,
        makingChargesPercent: dto.makingChargesPercent,
        wastagePercent: dto.wastagePercent,
        hasStones: this.hasStoneData(dto),
        stoneDetails: this.toStoneDetails(dto),
        stoneValue: dto.stoneValue ?? 0,
        purchaseRate: dto.purchaseRate,
        sellingPrice: dto.sellingPrice,
        purchaseDate: dto.purchaseDate ? new Date(dto.purchaseDate) : null,
        photos: dto.photoUrls === undefined ? undefined : dto.photoUrls,
        status: dto.status,
        location: dto.location,
        huid: dto.huid,
        hallmarkNumber: dto.hallmarkNumber,
        source: dto.source,
      },
    });
  }

  async previewReceiptOcr(file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('Receipt image is required');
    }

    const allowedMimeTypes = new Set([
      'image/jpeg',
      'image/jpg',
      'image/pjpeg',
      'image/png',
      'image/webp',
      'image/heic',
      'image/heif',
    ]);
    if (!allowedMimeTypes.has(file.mimetype)) {
      throw new BadRequestException(
        'Upload a JPG, PNG, WEBP, HEIC, or HEIF receipt image',
      );
    }

    const maxSizeBytes = 8 * 1024 * 1024;
    if (file.size > maxSizeBytes) {
      throw new BadRequestException('Receipt image must be 8 MB or smaller');
    }

    const apiKey = this.config.get<string>('GEMINI_API_KEY');
    if (!apiKey) {
      throw new ServiceUnavailableException('Gemini API key is not configured');
    }

    const ai = new GoogleGenAI({ apiKey });
    const response = await ai.models.generateContent({
      model: this.geminiModel,
      contents: [
        {
          text: [
            'Extract inventory rows from this Indian jewellery HUID or hallmark receipt.',
            'Return JSON only, with this exact shape:',
            '{"rows":[{"itemName":"string","tagNumber":"string|null","huid":"string|null","hallmarkNumber":"string|null","metalType":"gold|silver","karat":"string|null","grossWeight":0,"netWeight":0,"quantity":1}]}',
            'Use grams for weights as numbers. Normalize 22KT/22ct to 22K. Always return tagNumber as null because SwarnaLekh generates tags. Never copy HUID into tagNumber. If a field is missing, use null except quantity, which should default to 1. Do not invent HUIDs or weights.',
          ].join(' '),
        },
        {
          inlineData: {
            data: file.buffer.toString('base64'),
            mimeType: file.mimetype,
          },
        },
      ],
      config: {
        responseMimeType: 'application/json',
        temperature: 0,
      },
    });

    const parsed = this.parseOcrResponse(response.text);
    const rows = parsed.rows.map((row, index) =>
      this.normalizeOcrRow(row, index),
    );

    return {
      model: this.geminiModel,
      rows,
    };
  }

  async importItems(tenantId: string, dto: ImportInventoryDto) {
    return this.prisma.$transaction(async (tx) => {
      const existingTags = await tx.inventoryItem.findMany({
        where: { tenantId, tagNumber: { not: null } },
        select: { tagNumber: true },
      });
      const usedTags = new Set(
        existingTags.map((item) => item.tagNumber).filter(Boolean) as string[],
      );
      let nextTagNumber = this.getNextInventorySequence(usedTags);
      this.validateImportRows(dto.rows);

      const created = [];
      for (const row of dto.rows) {
        const tagNumber = this.formatInventoryTag(nextTagNumber++);
        usedTags.add(tagNumber);
        while (usedTags.has(this.formatInventoryTag(nextTagNumber))) {
          nextTagNumber++;
        }

        created.push(
          await tx.inventoryItem.create({
            data: this.toInventoryCreateData(tenantId, {
              ...row,
              tagNumber,
              source: row.source ?? 'ocr',
              stockType: row.stockType ?? 'unique',
              status: row.status ?? 'in_stock',
            }),
          }),
        );
      }

      return { createdCount: created.length, items: created };
    });
  }

  async remove(tenantId: string, id: string) {
    await this.findOne(tenantId, id);
    return this.prisma.inventoryItem.update({
      where: { id },
      data: {
        deletedAt: new Date(),
      },
    });
  }

  async getStats(tenantId: string, query: InventoryStatsQueryDto = {}) {
    const now = new Date();
    // "Sold" respects the selected period (default: this month).
    const soldRange = resolveDateRange(query.period, {
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      defaultPeriod: 'month',
    });
    const unsoldCutoff = new Date(now);
    unsoldCutoff.setDate(unsoldCutoff.getDate() - 90);

    const items = await this.prisma.inventoryItem.findMany({
      where: { tenantId, deletedAt: null },
      select: {
        metalType: true,
        stockType: true,
        quantity: true,
        grossWeight: true,
        netWeight: true,
        status: true,
        hasStones: true,
        stoneValue: true,
        purchaseRate: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    const inStockItems = items.filter((item) => item.status === 'in_stock');
    const soldItems = items.filter((item) => item.status === 'sold');
    const quantityByStatus = new Map<string, number>();

    for (const item of items) {
      quantityByStatus.set(
        item.status,
        (quantityByStatus.get(item.status) ?? 0) + item.quantity,
      );
    }

    const totalGoldWeight = this.sumMetalWeight(inStockItems, 'gold');
    const totalSilverWeight = this.sumMetalWeight(inStockItems, 'silver');
    const totalDiamondStock = inStockItems.filter(
      (item) => item.hasStones || this.toNumber(item.stoneValue) > 0,
    ).length;
    const soldThisMonth = soldItems.filter((item) => {
      if (!soldRange) return true; // all-time
      if (soldRange.gte && item.updatedAt < soldRange.gte) return false;
      if (soldRange.lte && item.updatedAt > soldRange.lte) return false;
      return true;
    }).length;
    const highValueProducts = inStockItems.filter(
      (item) => this.purchaseValue(item) >= 500000,
    ).length;
    const metalBreakdown = ['gold', 'silver'].map((metalType) => {
      const metalItems = inStockItems.filter(
        (item) => item.metalType === metalType,
      );
      return {
        metalType,
        count: metalItems.length,
        quantity: metalItems.reduce((sum, item) => sum + item.quantity, 0),
        totalWeight: this.round(this.sumMetalWeight(metalItems, metalType), 3),
      };
    });

    return {
      total: items.length,
      totalProducts: items.length,
      inStock: inStockItems.length,
      sold: soldItems.length,
      soldThisMonth,
      totalUnits: quantityByStatus.get('in_stock') ?? 0,
      soldUnits: quantityByStatus.get('sold') ?? 0,
      onApproval: quantityByStatus.get('on_approval') ?? 0,
      totalGoldWeight: this.round(totalGoldWeight, 3),
      totalGoldStock: this.round(totalGoldWeight, 3),
      totalSilverWeight: this.round(totalSilverWeight, 3),
      totalSilverStock: this.round(totalSilverWeight, 3),
      totalDiamondStock,
      alerts: {
        lowStock: inStockItems.filter(
          (item) => item.stockType === 'bulk' && item.quantity <= 2,
        ).length,
        outOfStock: soldItems.length,
        highValueProducts,
        unsoldProducts: inStockItems.filter(
          (item) => item.createdAt <= unsoldCutoff,
        ).length,
      },
      metalBreakdown,
    };
  }

  async getOverview(tenantId: string, filters?: InventoryFilters) {
    const [items, stats, latestRateDate] = await Promise.all([
      this.findAll(tenantId, filters),
      this.getStats(tenantId),
      this.prisma.dailyRate.findFirst({
        where: { tenantId },
        orderBy: { rateDate: 'desc' },
        select: { rateDate: true },
      }),
    ]);

    const rateDate = latestRateDate?.rateDate;
    const rates = rateDate
      ? await this.prisma.dailyRate.findMany({
          where: {
            tenantId,
            rateDate,
          },
          select: {
            metalType: true,
            karat: true,
            ratePerGram: true,
            rateDate: true,
          },
        })
      : [];

    const rateMap = new Map<string, number>();
    for (const rate of rates) {
      const key = `${rate.metalType}:${rate.karat ?? ''}`.toLowerCase();
      rateMap.set(key, Number(rate.ratePerGram));
    }

    const itemsWithValuation = items.map((item) => {
      const exactKey = `${item.metalType}:${item.karat ?? ''}`.toLowerCase();
      const fallbackKey = `${item.metalType}:`.toLowerCase();
      const purchaseRate = this.toNumber(item.purchaseRate);
      const currentRatePerGram =
        rateMap.get(exactKey) ??
        rateMap.get(fallbackKey) ??
        (purchaseRate > 0 ? purchaseRate : null);
      const netWeight = this.toNumber(item.netWeight);
      const quantity = item.quantity || 1;
      const makingCharges = this.calculateMakingCharges(
        item,
        currentRatePerGram,
      );
      const priceBreakdown =
        currentRatePerGram == null
          ? null
          : calculateItemPrice({
              netWeight,
              ratePerGram: currentRatePerGram,
              makingCharges,
              stoneValue: this.toNumber(item.stoneValue),
              wastagePercent: this.toNumber(item.wastagePercent),
            });
      const estimatedPerPieceValue = priceBreakdown?.metalValue ?? null;
      const calculatedSellingPrice = priceBreakdown?.itemTotal ?? null;
      const explicitSellingPrice =
        item.sellingPrice == null ? null : this.toNumber(item.sellingPrice);
      const finalSellingPrice =
        explicitSellingPrice ?? calculatedSellingPrice ?? null;
      const estimatedMetalValue =
        finalSellingPrice == null ? null : finalSellingPrice * quantity;

      return {
        ...item,
        productCode: item.tagNumber ?? item.barcode,
        designNumber: item.barcode,
        categoryName: item.category?.name ?? null,
        stoneWeight: this.stoneWeight(item.stoneDetails),
        currentRatePerGram,
        totalGrossWeight: this.toNumber(item.grossWeight) * quantity,
        totalNetWeight: netWeight * quantity,
        makingChargesValue: this.round(makingCharges),
        calculatedSellingPrice,
        finalSellingPrice,
        sellingPrice: explicitSellingPrice,
        estimatedSellingPrice: finalSellingPrice,
        estimatedTotalValue:
          finalSellingPrice == null
            ? null
            : this.round(finalSellingPrice * quantity),
        estimatedPerPieceValue:
          estimatedPerPieceValue == null
            ? null
            : Number(estimatedPerPieceValue.toFixed(2)),
        estimatedMetalValue:
          estimatedMetalValue == null
            ? null
            : Number(estimatedMetalValue.toFixed(2)),
        valuationDate: rateDate?.toISOString() ?? null,
      };
    });

    const estimatedInStockValue = itemsWithValuation.reduce((total, item) => {
      if (item.status !== 'in_stock') return total;
      return total + (item.estimatedMetalValue ?? 0);
    }, 0);

    return {
      items: itemsWithValuation,
      stats: {
        ...stats,
        estimatedInStockValue: Number(estimatedInStockValue.toFixed(2)),
        valuationDate: rateDate?.toISOString() ?? null,
      },
    };
  }

  async getSoldProducts(tenantId: string, filters?: SoldProductsFilters) {
    const search = filters?.search?.trim();
    const dateFrom = this.parseDate(filters?.dateFrom);
    const dateTo = this.parseDate(filters?.dateTo, true);

    const [invoices, manualItems] = await Promise.all([
      this.prisma.invoice.findMany({
        where: this.buildSoldProductsWhere(tenantId, filters),
        orderBy: [{ invoiceDate: 'desc' }, { createdAt: 'desc' }],
        select: {
          id: true,
          invoiceNumber: true,
          invoiceDate: true,
          createdAt: true,
          customerName: true,
          customerPhone: true,
          paymentMode: true,
          items: {
            select: {
              id: true,
              itemName: true,
              itemTotal: true,
              quantity: true,
              inventoryItemId: true,
            },
          },
        },
      }),
      this.prisma.inventoryItem.findMany({
        where: {
          tenantId,
          status: 'sold',
          deletedAt: null,
          invoiceItems: { none: {} },
          ...((dateFrom || dateTo) && {
            updatedAt: {
              ...(dateFrom && { gte: dateFrom }),
              ...(dateTo && { lte: dateTo }),
            },
          }),
          ...(search && {
            OR: [
              { itemName: { contains: search, mode: 'insensitive' } },
              { tagNumber: { contains: search, mode: 'insensitive' } },
              { barcode: { contains: search, mode: 'insensitive' } },
            ],
          }),
        },
        select: {
          id: true,
          itemName: true,
          tagNumber: true,
          updatedAt: true,
          sellingPrice: true,
          quantity: true,
        },
        orderBy: { updatedAt: 'desc' },
      }),
    ]);

    const soldFromInvoices = invoices.flatMap((invoice) =>
      invoice.items.map((item) => ({
        id: item.id,
        invoiceId: invoice.id,
        invoiceNumber: invoice.invoiceNumber,
        customerName: invoice.customerName,
        customerPhone: invoice.customerPhone,
        productName: item.itemName ?? 'Product',
        soldDate: invoice.invoiceDate ?? invoice.createdAt,
        sellingPrice: this.toNumber(item.itemTotal),
        paymentMethod: invoice.paymentMode,
        quantity: item.quantity,
        inventoryItemId: item.inventoryItemId,
      })),
    );

    const soldManually = manualItems.map((item) => ({
      id: item.id,
      invoiceId: null,
      invoiceNumber: '-',
      customerName: 'Manual Update',
      customerPhone: null,
      productName: item.itemName ?? item.tagNumber ?? 'Product',
      soldDate: item.updatedAt,
      sellingPrice: this.toNumber(item.sellingPrice) || 0,
      paymentMethod: '-',
      quantity: item.quantity,
      inventoryItemId: item.id,
    }));

    return [...soldFromInvoices, ...soldManually].sort(
      (a, b) => b.soldDate.getTime() - a.soldDate.getTime(),
    );
  }

  private toInventoryCreateData(
    tenantId: string,
    dto: CreateInventoryDto,
  ): Prisma.InventoryItemUncheckedCreateInput {
    return {
      tenantId,
      itemName: dto.itemName,
      barcode: dto.barcode,
      categoryId: dto.categoryId,
      metalType: dto.metalType,
      karat: dto.karat,
      stockType: dto.stockType ?? 'unique',
      quantity: dto.stockType === 'bulk' ? (dto.quantity ?? 1) : 1,
      grossWeight: dto.grossWeight,
      netWeight: dto.netWeight,
      tagNumber: dto.tagNumber,
      purity: dto.purity,
      makingChargesPerGram: dto.makingChargesPerGram,
      makingChargesFixed: dto.makingChargesFixed,
      makingChargesPercent: dto.makingChargesPercent,
      wastagePercent: dto.wastagePercent ?? 0,
      hasStones: this.hasStoneData(dto),
      stoneDetails: this.toStoneDetails(dto),
      stoneValue: dto.stoneValue ?? 0,
      purchaseRate: dto.purchaseRate,
      sellingPrice: dto.sellingPrice,
      purchaseDate: dto.purchaseDate ? new Date(dto.purchaseDate) : undefined,
      photos: dto.photoUrls?.length ? dto.photoUrls : undefined,
      status: dto.status ?? 'in_stock',
      location: dto.location,
      huid: dto.huid,
      hallmarkNumber: dto.hallmarkNumber,
      source: dto.source,
    };
  }

  private validateImportRows(rows: ImportInventoryRowDto[]) {
    rows.forEach((row, index) => {
      if (row.netWeight > row.grossWeight) {
        throw new BadRequestException(
          `Row ${index + 1}: net weight cannot be greater than gross weight`,
        );
      }
    });
  }

  private buildInventoryWhere(
    tenantId: string,
    filters?: InventoryFilters,
  ): Prisma.InventoryItemWhereInput {
    const search = filters?.search?.trim();
    const createdAt: Prisma.DateTimeFilter = {};
    const dateFrom = this.parseDate(filters?.dateFrom);
    const dateTo = this.parseDate(filters?.dateTo, true);
    if (dateFrom) createdAt.gte = dateFrom;
    if (dateTo) createdAt.lte = dateTo;

    return {
      tenantId,
      deletedAt: null,
      ...(filters?.status && { status: filters.status }),
      ...(filters?.metalType && { metalType: filters.metalType }),
      ...(filters?.categoryId && { categoryId: filters.categoryId }),
      ...(filters?.categoryName && {
        category: {
          name: { contains: filters.categoryName, mode: 'insensitive' },
        },
      }),
      ...(filters?.location && {
        location: { contains: filters.location, mode: 'insensitive' },
      }),
      ...((createdAt.gte || createdAt.lte) && { createdAt }),
      ...(search && {
        OR: [
          { itemName: { contains: search, mode: 'insensitive' } },
          { tagNumber: { contains: search, mode: 'insensitive' } },
          { barcode: { contains: search, mode: 'insensitive' } },
          { huid: { contains: search, mode: 'insensitive' } },
          { hallmarkNumber: { contains: search, mode: 'insensitive' } },
          {
            category: {
              name: { contains: search, mode: 'insensitive' },
            },
          },
        ],
      }),
    };
  }

  private buildSoldProductsWhere(
    tenantId: string,
    filters?: SoldProductsFilters,
  ): Prisma.InvoiceWhereInput {
    const search = filters?.search?.trim();
    const invoiceDate: Prisma.DateTimeFilter = {};
    const dateFrom = this.parseDate(filters?.dateFrom);
    const dateTo = this.parseDate(filters?.dateTo, true);
    if (dateFrom) invoiceDate.gte = dateFrom;
    if (dateTo) invoiceDate.lte = dateTo;

    return {
      tenantId,
      deletedAt: null,
      ...((invoiceDate.gte || invoiceDate.lte) && { invoiceDate }),
      ...(search && {
        OR: [
          { invoiceNumber: { contains: search, mode: 'insensitive' } },
          { customerName: { contains: search, mode: 'insensitive' } },
          { customerPhone: { contains: search } },
          { paymentMode: { contains: search, mode: 'insensitive' } },
          {
            items: {
              some: {
                itemName: { contains: search, mode: 'insensitive' },
              },
            },
          },
        ],
      }),
    };
  }

  private async resolveCategoryId(tenantId: string, dto: CreateInventoryDto) {
    if (dto.categoryId) return dto.categoryId;
    const categoryName = this.cleanString(dto.categoryName);
    if (!categoryName) return undefined;

    const existing = await this.prisma.category.findFirst({
      where: {
        tenantId,
        name: { equals: categoryName, mode: 'insensitive' },
      },
      select: { id: true },
    });
    if (existing) return existing.id;

    const created = await this.prisma.category.create({
      data: { tenantId, name: categoryName },
      select: { id: true },
    });
    return created.id;
  }

  private toStoneDetails(
    dto: CreateInventoryDto,
  ): Prisma.InputJsonValue | undefined {
    if (dto.stoneWeight == null) return undefined;
    return {
      stoneWeight: dto.stoneWeight,
    };
  }

  private hasStoneData(dto: CreateInventoryDto) {
    return (dto.stoneWeight ?? 0) > 0 || (dto.stoneValue ?? 0) > 0;
  }

  private parseDate(value?: string, endOfDay = false) {
    if (!value) return null;
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return null;
    if (endOfDay) date.setHours(23, 59, 59, 999);
    return date;
  }

  private toNumber(value: unknown): number {
    if (value == null) return 0;
    if (typeof value === 'number') return value;
    if (typeof value === 'string') return Number(value) || 0;
    if (
      typeof value === 'object' &&
      'toNumber' in value &&
      typeof value.toNumber === 'function'
    ) {
      return value.toNumber();
    }
    return Number(value) || 0;
  }

  private round(value: number, precision = 2) {
    return Number(value.toFixed(precision));
  }

  private sumMetalWeight(
    items: Array<{ metalType: string; netWeight: unknown; quantity: number }>,
    metalType: string,
  ) {
    return items.reduce((sum, item) => {
      if (item.metalType !== metalType) return sum;
      return sum + this.toNumber(item.netWeight) * item.quantity;
    }, 0);
  }

  private purchaseValue(item: {
    netWeight: unknown;
    quantity: number;
    purchaseRate: unknown;
    stoneValue: unknown;
  }) {
    return (
      this.toNumber(item.netWeight) *
        item.quantity *
        this.toNumber(item.purchaseRate) +
      this.toNumber(item.stoneValue) * item.quantity
    );
  }

  private calculateMakingCharges(
    item: {
      netWeight: unknown;
      makingChargesPerGram: unknown;
      makingChargesFixed: unknown;
      makingChargesPercent: unknown;
    },
    ratePerGram: number | null,
  ) {
    const perGram = this.toNumber(item.makingChargesPerGram);
    if (perGram > 0) return perGram * this.toNumber(item.netWeight);

    const fixed = this.toNumber(item.makingChargesFixed);
    if (fixed > 0) return fixed;

    const percent = this.toNumber(item.makingChargesPercent);
    if (percent > 0 && ratePerGram != null) {
      return (this.toNumber(item.netWeight) * ratePerGram * percent) / 100;
    }

    return 0;
  }

  private stoneWeight(stoneDetails: Prisma.JsonValue) {
    if (
      !stoneDetails ||
      typeof stoneDetails !== 'object' ||
      Array.isArray(stoneDetails)
    ) {
      return null;
    }
    const value = (stoneDetails as Record<string, unknown>).stoneWeight;
    return value == null ? null : this.toNumber(value);
  }

  private parseOcrResponse(text?: string): { rows: unknown[] } {
    if (!text) {
      throw new BadRequestException('Gemini did not return receipt data');
    }

    const cleaned = text
      .trim()
      .replace(/^```json\s*/i, '')
      .replace(/^```\s*/i, '')
      .replace(/\s*```$/i, '');

    try {
      const parsed = JSON.parse(cleaned) as { rows?: unknown };
      if (!Array.isArray(parsed.rows)) {
        throw new Error('Missing rows array');
      }
      return { rows: parsed.rows };
    } catch {
      throw new BadRequestException('Could not parse receipt OCR response');
    }
  }

  private normalizeOcrRow(row: unknown, index: number): OcrDraftRow {
    if (!row || typeof row !== 'object') {
      return this.emptyOcrRow(index, ['Could not read this receipt row']);
    }

    const raw = row as Record<string, unknown>;
    const itemName =
      this.cleanString(raw.itemName) ?? `Receipt Item ${index + 1}`;
    const metalType = this.normalizeMetalType(raw.metalType);
    const grossWeight = this.toPositiveNumber(raw.grossWeight);
    const netWeight = this.toPositiveNumber(raw.netWeight);
    const quantity = Math.max(
      1,
      Math.floor(this.toPositiveNumber(raw.quantity) ?? 1),
    );
    const warnings: string[] = [];

    if (!raw.itemName) warnings.push('Missing item name');
    if (!grossWeight) warnings.push('Missing gross weight');
    if (!netWeight) warnings.push('Missing net weight');
    if (grossWeight && netWeight && netWeight > grossWeight)
      warnings.push('Net weight is greater than gross weight');
    if (!raw.huid && !raw.hallmarkNumber)
      warnings.push('Missing HUID or hallmark number');

    return {
      itemName,
      tagNumber: null,
      huid: this.cleanString(raw.huid),
      hallmarkNumber: this.cleanString(raw.hallmarkNumber),
      metalType,
      karat: this.normalizeKarat(raw.karat),
      grossWeight,
      netWeight,
      quantity,
      warnings,
    };
  }

  private emptyOcrRow(index: number, warnings: string[]): OcrDraftRow {
    return {
      itemName: `Receipt Item ${index + 1}`,
      tagNumber: null,
      huid: null,
      hallmarkNumber: null,
      metalType: 'gold',
      karat: null,
      grossWeight: null,
      netWeight: null,
      quantity: 1,
      warnings,
    };
  }

  private cleanString(value: unknown): string | null {
    if (typeof value !== 'string') return null;
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : null;
  }

  private toPositiveNumber(value: unknown): number | null {
    const numberValue =
      typeof value === 'number'
        ? value
        : Number.parseFloat(String(value ?? ''));
    if (!Number.isFinite(numberValue) || numberValue <= 0) return null;
    return Number(numberValue.toFixed(3));
  }

  private normalizeMetalType(value: unknown): string {
    const text = String(value ?? '')
      .trim()
      .toLowerCase();
    if (['gold', 'silver'].includes(text)) return text;
    if (text.includes('gold')) return 'gold';
    if (text.includes('silver')) return 'silver';
    return 'gold';
  }

  private normalizeKarat(value: unknown): string | null {
    const text = this.cleanString(value)?.toUpperCase().replace(/\s+/g, '');
    if (!text) return null;
    return text.replace(/KT|CT$/, 'K');
  }

  private getNextInventorySequence(tags: Set<string>): number {
    let max = 0;
    for (const tag of tags) {
      const match = /^INV-(\d+)$/i.exec(tag);
      if (match) max = Math.max(max, Number.parseInt(match[1], 10));
    }
    return max + 1;
  }

  private formatInventoryTag(value: number): string {
    return `INV-${value.toString().padStart(4, '0')}`;
  }
}
