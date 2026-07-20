import { GoogleGenAI } from '@google/genai';
import {
  BadRequestException,
  ConflictException,
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
  huid: string | null;
  metalType: string;
  karat: string | null;
  grossWeight: number | null;
  netWeight: number | null;
  stoneWeight: number | null;
  category: string | null;
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
  period?: string;
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
    return this.prisma.$transaction(async (tx) => {
      const tagNumber = await this.resolveTagNumber(
        tx,
        tenantId,
        categoryId,
        dto.tagNumber,
      );
      return tx.inventoryItem.create({
        data: this.toInventoryCreateData(tenantId, {
          ...dto,
          categoryId,
          tagNumber,
        }),
      });
    });
  }

  /// Resolves the tag for one item: a typed tag wins (numeric shorthand like
  /// "2" expands to the category sequence "PD-0002"; anything else is kept
  /// verbatim, e.g. a re-used physical tag from a HUID import), and must be
  /// unique in the shop or it 409s. With no typed tag, a fresh category
  /// sequence is handed out. Returns undefined when neither applies.
  private async resolveTagNumber(
    tx: Prisma.TransactionClient,
    tenantId: string,
    categoryId: string | undefined,
    rawTag: string | undefined,
  ): Promise<string | undefined> {
    const typed = this.cleanString(rawTag);
    if (typed) {
      const tagNumber = await this.expandNumericTag(
        tx,
        tenantId,
        categoryId,
        typed,
      );
      const clash = await tx.inventoryItem.findFirst({
        where: { tenantId, tagNumber, deletedAt: null },
        select: { id: true },
      });
      if (clash) {
        throw new ConflictException(
          `Tag "${tagNumber}" is already used by another item in stock.`,
        );
      }
      return tagNumber;
    }
    return categoryId
      ? await this.nextCategoryTag(tx, tenantId, categoryId)
      : undefined;
  }

  /// Expands a bare number ("2") into the item's category sequence tag
  /// ("PD-0002"). A tag that already carries letters is returned as-is.
  private async expandNumericTag(
    tx: Prisma.TransactionClient,
    tenantId: string,
    categoryId: string | undefined,
    typed: string,
  ): Promise<string> {
    if (!/^\d+$/.test(typed) || !categoryId) return typed;
    const category = await tx.category.findFirst({
      where: { id: categoryId, tenantId },
      select: { prefix: true },
    });
    if (!category?.prefix) return typed;
    return `${category.prefix}-${typed.padStart(4, '0')}`;
  }

  /// Hands out the next RG-0001-style tag for the item's category. The atomic
  /// nextSequence increment row-locks the category, so concurrent creates
  /// serialize and never share a number; the clash loop only skips numbers
  /// already taken by manually-entered tags.
  private async nextCategoryTag(
    tx: Prisma.TransactionClient,
    tenantId: string,
    categoryId: string,
  ): Promise<string | undefined> {
    const category = await tx.category.findFirst({
      where: { id: categoryId, tenantId },
      select: { prefix: true },
    });
    if (!category?.prefix) return undefined;

    for (;;) {
      const bumped = await tx.category.update({
        where: { id: categoryId },
        data: { nextSequence: { increment: 1 } },
        select: { prefix: true, nextSequence: true },
      });
      const sequence = bumped.nextSequence - 1;
      const tagNumber = `${bumped.prefix}-${sequence
        .toString()
        .padStart(4, '0')}`;
      const clash = await tx.inventoryItem.findFirst({
        where: { tenantId, tagNumber },
        select: { id: true },
      });
      if (!clash) return tagNumber;
    }
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
            '{"rows":[{"itemName":"string","huid":"string|null","metalType":"gold|silver","karat":"string|null","grossWeight":0,"netWeight":0,"stoneWeight":0,"category":"string|null"}]}',
            'Use grams for weights as numbers. Normalize 22KT/22ct to 22K.',
            'stoneWeight is the stone/wastage deduction in grams; null when the receipt shows none.',
            'category is the ornament type when identifiable, one of: Ring, Chain, Mangalsutra, Necklace, Bangle, Bracelet, Earrings, Pendant, Anklet, Nose Pin, Kada, Haar, Maang Tikka, Toe Ring, Coin, Locket, Studs, Choker, Waist Chain, Armlet; otherwise null.',
            'If a field is missing, use null. Do not invent HUIDs or weights.',
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
      this.validateImportRows(dto.rows);
      await this.assertNoDuplicateHuids(tx, tenantId, dto.rows);

      // Rows with a category get RG-01-style tags; category-less rows fall
      // back to the legacy flat INV-#### sequence.
      const categoryIds = [
        ...new Set(
          dto.rows.map((row) => row.categoryId).filter(Boolean) as string[],
        ),
      ];
      if (categoryIds.length > 0) {
        const owned = await tx.category.findMany({
          where: { id: { in: categoryIds }, tenantId },
          select: { id: true },
        });
        if (owned.length !== categoryIds.length) {
          throw new BadRequestException('Unknown category');
        }
      }

      const existingTags = await tx.inventoryItem.findMany({
        where: { tenantId, tagNumber: { not: null } },
        select: { tagNumber: true },
      });
      const usedTags = new Set(
        existingTags.map((item) => item.tagNumber).filter(Boolean) as string[],
      );
      let nextTagNumber = this.getNextInventorySequence(usedTags);

      const created = [];
      for (const row of dto.rows) {
        // A typed tag (e.g. the item's existing physical tag, or "2" →
        // "PD-0002") wins and is uniqueness-checked; otherwise fall back to a
        // category sequence, then the flat INV-#### sequence.
        let tagNumber = await this.resolveTagNumber(
          tx,
          tenantId,
          row.categoryId,
          row.tagNumber,
        );
        if (tagNumber) {
          usedTags.add(tagNumber);
        } else {
          tagNumber = this.formatInventoryTag(nextTagNumber++);
          usedTags.add(tagNumber);
          while (usedTags.has(this.formatInventoryTag(nextTagNumber))) {
            nextTagNumber++;
          }
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

  /// Req §2.2: a HUID that is currently in stock must not be imported again;
  /// a sold item's HUID may re-enter (buy-back). Also rejects the same HUID
  /// appearing twice within one import batch.
  private async assertNoDuplicateHuids(
    tx: Prisma.TransactionClient,
    tenantId: string,
    rows: ImportInventoryRowDto[],
  ) {
    const huids = rows
      .map((row) => this.cleanString(row.huid))
      .filter(Boolean) as string[];
    if (huids.length === 0) return;

    const seen = new Set<string>();
    for (const huid of huids) {
      if (seen.has(huid)) {
        throw new ConflictException(
          `HUID ${huid} appears more than once in this import`,
        );
      }
      seen.add(huid);
    }

    const inStock = await tx.inventoryItem.findMany({
      where: {
        tenantId,
        deletedAt: null,
        status: 'in_stock',
        huid: { in: huids },
      },
      select: { huid: true },
    });
    if (inStock.length > 0) {
      const list = inStock.map((item) => item.huid).join(', ');
      throw new ConflictException(`HUID already in stock: ${list}`);
    }
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
        karat: true,
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

    // Sold-by-period counts from the actual sale date (invoice date), not
    // the item's updatedAt — editing an item after sale must not move it
    // between periods. Manual status flips (no invoice) keep updatedAt as
    // the only date they have.
    const [soldViaInvoices, soldManually] = await Promise.all([
      this.prisma.invoiceItem.count({
        where: {
          invoice: {
            tenantId,
            deletedAt: null,
            ...(soldRange && {
              invoiceDate: {
                ...(soldRange.gte && { gte: soldRange.gte }),
                ...(soldRange.lte && { lte: soldRange.lte }),
              },
            }),
          },
        },
      }),
      this.prisma.inventoryItem.count({
        where: {
          tenantId,
          deletedAt: null,
          status: 'sold',
          invoiceItems: { none: {} },
          ...(soldRange && {
            updatedAt: {
              ...(soldRange.gte && { gte: soldRange.gte }),
              ...(soldRange.lte && { lte: soldRange.lte }),
            },
          }),
        },
      }),
    ]);

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
    const soldThisMonth = soldViaInvoices + soldManually;
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

    // Per-karat split of the in-stock weight tiles (tap-through detail).
    const karatBreakdown = ['gold', 'silver'].map((metalType) => {
      const byKarat = new Map<string, { count: number; weight: number }>();
      for (const item of inStockItems) {
        if (item.metalType !== metalType) continue;
        const karat = item.karat ?? 'Other';
        const entry = byKarat.get(karat) ?? { count: 0, weight: 0 };
        entry.count += item.quantity;
        entry.weight += this.toNumber(item.netWeight) * item.quantity;
        byKarat.set(karat, entry);
      }
      return {
        metalType,
        karats: [...byKarat.entries()]
          .map(([karat, entry]) => ({
            karat,
            count: entry.count,
            totalWeight: this.round(entry.weight, 3),
          }))
          .sort((a, b) => b.totalWeight - a.totalWeight),
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
      karatBreakdown,
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
    // Presets (today/month/…) and custom from/to both resolve to one range,
    // applied to the invoice date (real sold date). Default: all time.
    const range = resolveDateRange(this.soldPeriodOf(filters), {
      dateFrom: filters?.dateFrom,
      dateTo: filters?.dateTo,
      defaultPeriod: 'all',
    });
    const dateFrom = range?.gte ?? null;
    const dateTo = range?.lte ?? null;

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
              inventoryItem: {
                select: {
                  tagNumber: true,
                  metalType: true,
                  karat: true,
                  netWeight: true,
                  category: { select: { name: true } },
                },
              },
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
          metalType: true,
          karat: true,
          netWeight: true,
          category: { select: { name: true } },
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
        tagNumber: item.inventoryItem?.tagNumber ?? null,
        categoryName: item.inventoryItem?.category?.name ?? null,
        metalType: item.inventoryItem?.metalType ?? null,
        karat: item.inventoryItem?.karat ?? null,
        netWeight: item.inventoryItem
          ? this.toNumber(item.inventoryItem.netWeight)
          : null,
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
      tagNumber: item.tagNumber,
      categoryName: item.category?.name ?? null,
      metalType: item.metalType,
      karat: item.karat,
      netWeight: this.toNumber(item.netWeight),
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

  /// Bare dateFrom/dateTo without a period (legacy callers) means custom.
  private soldPeriodOf(filters?: SoldProductsFilters): string | undefined {
    if (filters?.period) return filters.period;
    return filters?.dateFrom || filters?.dateTo ? 'custom' : undefined;
  }

  private buildSoldProductsWhere(
    tenantId: string,
    filters?: SoldProductsFilters,
  ): Prisma.InvoiceWhereInput {
    const search = filters?.search?.trim();
    const invoiceDate: Prisma.DateTimeFilter = {};
    const range = resolveDateRange(this.soldPeriodOf(filters), {
      dateFrom: filters?.dateFrom,
      dateTo: filters?.dateTo,
      defaultPeriod: 'all',
    });
    if (range?.gte) invoiceDate.gte = range.gte;
    if (range?.lte) invoiceDate.lte = range.lte;

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
    if (dto.categoryId) {
      // Never trust a client-supplied id across tenants.
      const owned = await this.prisma.category.findFirst({
        where: { id: dto.categoryId, tenantId },
        select: { id: true },
      });
      if (!owned) throw new BadRequestException('Unknown category');
      return dto.categoryId;
    }
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
    // Surface the deduction explicitly: receipts often carry only gross/net,
    // and the user should see WHY net is lower (req §2.1).
    const stoneWeight =
      this.toPositiveNumber(raw.stoneWeight) ??
      (grossWeight && netWeight && grossWeight > netWeight
        ? Number((grossWeight - netWeight).toFixed(3))
        : null);
    const warnings: string[] = [];

    if (!raw.itemName) warnings.push('Missing item name');
    if (!grossWeight) warnings.push('Missing gross weight');
    if (!netWeight) warnings.push('Missing net weight');
    if (grossWeight && netWeight && netWeight > grossWeight)
      warnings.push('Net weight is greater than gross weight');
    if (!raw.huid) warnings.push('Missing HUID');

    return {
      itemName,
      huid: this.cleanString(raw.huid),
      metalType,
      karat: this.normalizeKarat(raw.karat),
      grossWeight,
      netWeight,
      stoneWeight,
      category: this.cleanString(raw.category),
      warnings,
    };
  }

  private emptyOcrRow(index: number, warnings: string[]): OcrDraftRow {
    return {
      itemName: `Receipt Item ${index + 1}`,
      huid: null,
      metalType: 'gold',
      karat: null,
      grossWeight: null,
      netWeight: null,
      stoneWeight: null,
      category: null,
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
