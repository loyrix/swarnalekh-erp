import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service.js';
import { AddInvoicePaymentDto, CreateInvoiceDto } from './invoice.dto.js';
import { Prisma } from '@prisma/client';
import {
  calculateInvoiceTotals,
  calculateItemPrice,
  calculateOldGoldValue,
} from '@swarnbook/business-logic';

type InvoiceFilters = {
  search?: string;
  dateFrom?: string;
  dateTo?: string;
};

const invoiceDetailInclude = {
  items: true,
  customer: true,
  creator: { select: { id: true, name: true } },
  payments: true,
} satisfies Prisma.InvoiceInclude;

type PrintableInvoice = {
  shop: {
    name: string;
    ownerName: string | null;
    phone: string | null;
    email: string | null;
    address: string | null;
    city: string | null;
    state: string | null;
    pincode: string | null;
    gstin: string | null;
    pan: string | null;
    logoUrl: string | null;
  };
  invoice: {
    id: string;
    invoiceNumber: string;
    invoiceDate: Date;
    customerName: string | null;
    customerPhone: string | null;
    customerGstin: string | null;
    paymentMode: string | null;
    items: Array<{
      itemName: string;
      quantity: number;
      metalType: string | null;
      karat: string | null;
      grossWeight: number;
      netWeight: number;
      ratePerGram: number;
      metalValue: number;
      makingCharges: number;
      stoneValue: number;
      wastageValue: number;
      hallmarkNumber: string | null;
      huid: string | null;
      itemTotal: number;
    }>;
    subtotal: number;
    totalMakingCharges: number;
    totalStoneValue: number;
    discountAmount: number;
    oldGoldValue: number;
    taxableAmount: number;
    cgstPercent: number;
    cgstAmount: number;
    sgstPercent: number;
    sgstAmount: number;
    igstPercent: number;
    igstAmount: number;
    totalTax: number;
    grandTotal: number;
    roundOff: number;
    amountPaid: number;
    balanceDue: number;
    notes: string | null;
    payments: Array<{
      id: string;
      amount: number;
      paymentMode: string;
      paymentDate: Date;
      referenceNumber: string | null;
      notes: string | null;
    }>;
  };
  qrPayload: string;
  verificationCode: string;
  generatedAt: string;
};

type PdfLogoImage = {
  bytes: Buffer;
  width: number;
  height: number;
};

@Injectable()
export class InvoiceService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Computes customer, priced line items, and totals for an invoice WITHOUT
   * mutating stock. Shared by `previewInvoice` (read-only) and `createInvoice`
   * (which then persists + reduces stock). When `lock` is set, each inventory
   * row is locked `FOR UPDATE` so concurrent invoices for the same unique item
   * cannot oversell.
   */
  private async computeInvoice(
    tx: Prisma.TransactionClient,
    tenantId: string,
    dto: CreateInvoiceDto,
    options: { lock: boolean },
  ) {
    let customerName: string | undefined | null = dto.customerName;
    let customerPhone: string | undefined | null = dto.customerPhone;

    if (dto.customerId) {
      const customer = await tx.customer.findFirst({
        where: { id: dto.customerId, tenantId },
      });
      if (customer) {
        customerName = customer.name;
        customerPhone = customer.phone;
      } else {
        throw new NotFoundException('Customer not found');
      }
    } else if (!customerName) {
      throw new BadRequestException('Customer Name or ID is required');
    }

    if (dto.items.length === 0) {
      throw new BadRequestException(
        'At least one item is required in the invoice',
      );
    }

    let subtotal = new Prisma.Decimal(0);
    let totalMakingCharges = new Prisma.Decimal(0);
    let totalStoneValue = new Prisma.Decimal(0);

    const lines: Array<{
      invItemId: string;
      stockType: string;
      availableQuantity: number;
      requestedQuantity: number;
      input: Prisma.InvoiceItemUncheckedCreateWithoutInvoiceInput;
    }> = [];

    for (const itemDto of dto.items) {
      // Lock the inventory row for the duration of the transaction so a
      // concurrent invoice for the same item waits and re-reads a fresh status.
      if (options.lock) {
        await tx.$queryRaw`SELECT id FROM inventory_items WHERE id = ${itemDto.inventoryItemId}::uuid AND tenant_id = ${tenantId}::uuid FOR UPDATE`;
      }

      const invItem = await tx.inventoryItem.findFirst({
        where: { id: itemDto.inventoryItemId, tenantId },
      });

      if (!invItem) {
        throw new NotFoundException(
          `Inventory item ${itemDto.inventoryItemId} not found`,
        );
      }
      if (invItem.status === 'sold') {
        throw new BadRequestException(
          `Item ${invItem.tagNumber || invItem.id} is already sold.`,
        );
      }

      const requestedQuantity = Math.max(1, Math.floor(itemDto.quantity ?? 1));
      const availableQuantity =
        invItem.stockType === 'bulk' ? invItem.quantity : 1;

      if (invItem.stockType === 'unique' && requestedQuantity !== 1) {
        throw new BadRequestException(
          `Unique item ${invItem.tagNumber || invItem.itemName || invItem.id} can only be sold as a single piece.`,
        );
      }

      if (requestedQuantity > availableQuantity) {
        throw new BadRequestException(
          `Only ${availableQuantity} piece(s) available for ${invItem.tagNumber || invItem.itemName || invItem.id}.`,
        );
      }

      const explicitSellingPricePerPiece = this.toNumber(invItem.sellingPrice);
      const hasExplicitSellingPrice = explicitSellingPricePerPiece > 0;
      // Empty-string karat is treated as "unspecified".
      const itemKarat = invItem.karat?.trim() ? invItem.karat.trim() : null;
      const orderBy = [
        { rateDate: 'desc' as const },
        { createdAt: 'desc' as const },
      ];
      const findRate = (karat: string | null | undefined) =>
        tx.dailyRate.findFirst({
          where: {
            tenantId,
            metalType: { equals: invItem.metalType, mode: 'insensitive' },
            // `undefined` drops the karat filter entirely (match any karat).
            ...(karat === undefined ? {} : { karat }),
          },
          orderBy,
        });
      const rateRecord = hasExplicitSellingPrice
        ? null
        : ((await findRate(itemKarat)) ?? // exact karat (or explicit null)
          (await findRate(null)) ?? // legacy metal-wide (null karat) rate
          // Item has no karat → fall back to any rate set for the metal.
          (itemKarat === null ? await findRate(undefined) : null));

      if (!hasExplicitSellingPrice && !rateRecord) {
        const metalLabel = itemKarat
          ? `${invItem.metalType} ${itemKarat}`
          : invItem.metalType;
        throw new BadRequestException(
          `No rate set for ${metalLabel}. Please set rates first.`,
        );
      }

      const ratePerGram = rateRecord?.ratePerGram ?? null;
      const componentRatePerGram =
        ratePerGram?.toNumber() ?? this.toNumber(invItem.purchaseRate);
      const grossWeightPerPiece = invItem.grossWeight.toNumber();
      const netWeightPerPiece = invItem.netWeight.toNumber();
      const grossWeight = grossWeightPerPiece * requestedQuantity;
      const netWeight = netWeightPerPiece * requestedQuantity;
      const stoneValue =
        (invItem.stoneValue?.toNumber() ?? 0) * requestedQuantity;

      let makingCharges = 0;
      if (itemDto.makingCharges !== undefined) {
        makingCharges = itemDto.makingCharges;
      } else if (invItem.makingChargesFixed) {
        makingCharges =
          invItem.makingChargesFixed.toNumber() * requestedQuantity;
      } else if (invItem.makingChargesPerGram) {
        makingCharges = invItem.makingChargesPerGram.toNumber() * grossWeight;
      } else if (invItem.makingChargesPercent && componentRatePerGram > 0) {
        makingCharges =
          (netWeight *
            componentRatePerGram *
            invItem.makingChargesPercent.toNumber()) /
          100;
      }

      const itemBreakdown = hasExplicitSellingPrice
        ? this.explicitSellingPriceBreakdown({
            lineTotal: explicitSellingPricePerPiece * requestedQuantity,
            netWeight,
            componentRatePerGram,
            makingCharges,
            stoneValue,
            wastagePercent: invItem.wastagePercent.toNumber(),
          })
        : calculateItemPrice({
            netWeight,
            ratePerGram: ratePerGram!.toNumber(),
            makingCharges,
            stoneValue,
            wastagePercent: invItem.wastagePercent.toNumber(),
          });

      subtotal = new Prisma.Decimal(
        subtotal.toNumber() + itemBreakdown.itemTotal,
      );
      totalMakingCharges = new Prisma.Decimal(
        totalMakingCharges.toNumber() + itemBreakdown.makingCharges,
      );
      totalStoneValue = new Prisma.Decimal(
        totalStoneValue.toNumber() + itemBreakdown.stoneValue,
      );

      lines.push({
        invItemId: invItem.id,
        stockType: invItem.stockType,
        availableQuantity,
        requestedQuantity,
        input: {
          inventoryItemId: invItem.id,
          itemName:
            invItem.stockType === 'bulk'
              ? `${invItem.itemName || invItem.tagNumber || 'Item'} x${requestedQuantity}`
              : invItem.itemName || invItem.tagNumber || undefined,
          quantity: requestedQuantity,
          metalType: invItem.metalType,
          karat: invItem.karat || undefined,
          grossWeight: new Prisma.Decimal(grossWeight),
          netWeight: new Prisma.Decimal(netWeight),
          ratePerGram,
          metalValue: new Prisma.Decimal(itemBreakdown.metalValue),
          makingCharges: new Prisma.Decimal(itemBreakdown.makingCharges),
          stoneValue: new Prisma.Decimal(itemBreakdown.stoneValue),
          wastageValue: new Prisma.Decimal(itemBreakdown.wastageValue),
          hallmarkNumber: invItem.hallmarkNumber,
          huid: invItem.huid,
          itemTotal: new Prisma.Decimal(itemBreakdown.itemTotal),
        },
      });
    }

    let oldGoldValue = 0;
    if (dto.oldGoldWeight && dto.oldGoldRate) {
      oldGoldValue = calculateOldGoldValue(dto.oldGoldWeight, dto.oldGoldRate);
    }

    const totals = calculateInvoiceTotals({
      itemTotals: lines.map((line) => this.toNumber(line.input.itemTotal)),
      discountAmount: dto.discountAmount || 0,
      oldGoldValue,
    });

    return {
      customerName,
      customerPhone,
      subtotal,
      totalMakingCharges,
      totalStoneValue,
      oldGoldValue,
      totals,
      lines,
    };
  }

  /**
   * Server-computed pricing preview for the "New Bill" screen. Runs the exact
   * same pricing as `createInvoice` (so the shown total equals the charged
   * total) but persists nothing and does not touch stock.
   */
  async previewInvoice(tenantId: string, dto: CreateInvoiceDto) {
    const computed = await this.prisma.$transaction((tx) =>
      this.computeInvoice(tx, tenantId, dto, { lock: false }),
    );
    const t = computed.totals;
    return {
      customerName: computed.customerName ?? null,
      customerPhone: computed.customerPhone ?? null,
      items: computed.lines.map((line) => ({
        inventoryItemId: line.invItemId,
        itemName: line.input.itemName ?? null,
        quantity: line.input.quantity ?? 1,
        grossWeight: this.toNumber(line.input.grossWeight),
        netWeight: this.toNumber(line.input.netWeight),
        ratePerGram: this.toNumber(line.input.ratePerGram),
        metalValue: this.toNumber(line.input.metalValue),
        makingCharges: this.toNumber(line.input.makingCharges),
        stoneValue: this.toNumber(line.input.stoneValue),
        itemTotal: this.toNumber(line.input.itemTotal),
      })),
      subtotal: this.toNumber(computed.subtotal),
      totalMakingCharges: this.toNumber(computed.totalMakingCharges),
      totalStoneValue: this.toNumber(computed.totalStoneValue),
      discountAmount: t.discountAmount,
      oldGoldValue: t.oldGoldValue,
      taxableAmount: t.taxableAmount,
      cgstPercent: t.cgstPercent,
      cgstAmount: t.cgstAmount,
      sgstPercent: t.sgstPercent,
      sgstAmount: t.sgstAmount,
      totalTax: t.totalTax,
      grandTotal: t.grandTotal,
      roundOff: t.roundOff,
    };
  }

  async createInvoice(tenantId: string, userId: string, dto: CreateInvoiceDto) {
    // Idempotency: a repeated submit with the same key returns the first result
    // instead of creating a duplicate invoice + double-reducing stock.
    if (dto.idempotencyKey) {
      const existing = await this.prisma.invoice.findFirst({
        where: { tenantId, idempotencyKey: dto.idempotencyKey },
        include: { items: true },
      });
      if (existing) return existing;
    }

    try {
      return await this.prisma.$transaction(async (tx) => {
        const computed = await this.computeInvoice(tx, tenantId, dto, {
          lock: true,
        });

        const year = new Date().getFullYear();
        const startOfYear = new Date(year, 0, 1);
        const count = await tx.invoice.count({
          where: { tenantId, createdAt: { gte: startOfYear } },
        });
        const invoiceNumber = `SLK-${year}-${String(count + 1).padStart(4, '0')}`;

        const totals = computed.totals;
        const invoice = await tx.invoice.create({
          data: {
            tenantId,
            invoiceNumber,
            idempotencyKey: dto.idempotencyKey,
            customerId: dto.customerId,
            customerName: computed.customerName,
            customerPhone: computed.customerPhone,
            subtotal: computed.subtotal,
            totalMakingCharges: computed.totalMakingCharges,
            totalStoneValue: computed.totalStoneValue,
            discountAmount: new Prisma.Decimal(totals.discountAmount),
            oldGoldWeight: dto.oldGoldWeight,
            oldGoldKarat: dto.oldGoldKarat,
            oldGoldRate: dto.oldGoldRate,
            oldGoldValue: new Prisma.Decimal(totals.oldGoldValue),
            taxableAmount: new Prisma.Decimal(totals.taxableAmount),
            cgstPercent: new Prisma.Decimal(totals.cgstPercent),
            cgstAmount: new Prisma.Decimal(totals.cgstAmount),
            sgstPercent: new Prisma.Decimal(totals.sgstPercent),
            sgstAmount: new Prisma.Decimal(totals.sgstAmount),
            totalTax: new Prisma.Decimal(totals.totalTax),
            grandTotal: new Prisma.Decimal(totals.grandTotal),
            roundOff: new Prisma.Decimal(totals.roundOff),
            createdBy: userId,
            notes: dto.notes,
            amountPaid: dto.amountPaid || 0,
            balanceDue: totals.grandTotal - (dto.amountPaid || 0),
            paymentMode: dto.paymentMode,
            items: { create: computed.lines.map((line) => line.input) },
          },
          include: { items: true },
        });

        // Reduce stock for each sold line.
        for (const line of computed.lines) {
          if (line.stockType === 'bulk') {
            const remainingQuantity =
              line.availableQuantity - line.requestedQuantity;
            await tx.inventoryItem.update({
              where: { id: line.invItemId },
              data: {
                quantity: remainingQuantity,
                status: remainingQuantity > 0 ? 'in_stock' : 'sold',
              },
            });
          } else {
            await tx.inventoryItem.update({
              where: { id: line.invItemId },
              data: { status: 'sold' },
            });
          }
        }

        if (dto.amountPaid && dto.amountPaid > 0) {
          await tx.payment.create({
            data: {
              tenantId,
              invoiceId: invoice.id,
              customerId: dto.customerId,
              amount: dto.amountPaid,
              paymentMode: dto.paymentMode || 'cash',
            },
          });
        }

        if (dto.customerId) {
          await tx.customer.update({
            where: { id: dto.customerId },
            data: {
              totalPurchases: { increment: invoice.grandTotal },
              totalVisits: { increment: 1 },
              lastVisitAt: new Date(),
            },
          });
        }

        return invoice;
      });
    } catch (error) {
      // Idempotency race: a concurrent request with the same key won the unique
      // index — return the already-created invoice instead of surfacing P2002.
      if (
        dto.idempotencyKey &&
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const existing = await this.prisma.invoice.findFirst({
          where: { tenantId, idempotencyKey: dto.idempotencyKey },
          include: { items: true },
        });
        if (existing) return existing;
      }
      throw error;
    }
  }

  /**
   * Records a partial (or final) payment against an existing invoice and moves
   * `amountPaid`/`balanceDue`. Runs in a transaction so the payment row and the
   * invoice totals stay consistent. Blocks over-payment beyond the balance.
   */
  async addPayment(
    tenantId: string,
    invoiceId: string,
    dto: AddInvoicePaymentDto,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const invoice = await tx.invoice.findFirst({
        where: { id: invoiceId, tenantId, deletedAt: null },
        select: {
          id: true,
          customerId: true,
          grandTotal: true,
          amountPaid: true,
          balanceDue: true,
          paymentMode: true,
        },
      });
      if (!invoice) {
        throw new NotFoundException('Invoice not found');
      }

      const amount = this.round(dto.amount);
      if (amount <= 0) {
        throw new BadRequestException(
          'Payment amount must be greater than zero',
        );
      }

      const balanceDue = this.toNumber(invoice.balanceDue);
      if (amount > balanceDue + 0.01) {
        throw new BadRequestException(
          `Payment of ${amount.toFixed(2)} exceeds the balance due of ${balanceDue.toFixed(2)}.`,
        );
      }

      const newPaid = this.round(this.toNumber(invoice.amountPaid) + amount);
      const newBalance = this.round(
        Math.max(0, this.toNumber(invoice.grandTotal) - newPaid),
      );

      const payment = await tx.payment.create({
        data: {
          tenantId,
          invoiceId: invoice.id,
          customerId: invoice.customerId,
          amount: new Prisma.Decimal(amount),
          paymentMode: dto.paymentMode || invoice.paymentMode || 'cash',
          referenceNumber: dto.referenceNumber,
          notes: dto.notes,
        },
      });

      const updated = await tx.invoice.update({
        where: { id: invoice.id },
        data: {
          amountPaid: new Prisma.Decimal(newPaid),
          balanceDue: new Prisma.Decimal(newBalance),
        },
        select: {
          id: true,
          grandTotal: true,
          amountPaid: true,
          balanceDue: true,
        },
      });

      return {
        payment: this.serializePayment(payment),
        invoice: {
          id: updated.id,
          grandTotal: this.toNumber(updated.grandTotal),
          amountPaid: this.toNumber(updated.amountPaid),
          balanceDue: this.toNumber(updated.balanceDue),
        },
      };
    });
  }

  async getInvoicePayments(tenantId: string, invoiceId: string) {
    const invoice = await this.prisma.invoice.findFirst({
      where: { id: invoiceId, tenantId, deletedAt: null },
      select: { id: true },
    });
    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }
    const payments = await this.prisma.payment.findMany({
      where: { tenantId, invoiceId },
      orderBy: { createdAt: 'desc' },
    });
    return payments.map((payment) => this.serializePayment(payment));
  }

  private serializePayment(payment: {
    id: string;
    amount: Prisma.Decimal;
    paymentMode: string;
    paymentDate: Date;
    referenceNumber: string | null;
    notes: string | null;
    createdAt: Date;
  }) {
    return {
      id: payment.id,
      amount: this.toNumber(payment.amount),
      paymentMode: payment.paymentMode,
      paymentDate: payment.paymentDate,
      referenceNumber: payment.referenceNumber,
      notes: payment.notes,
      createdAt: payment.createdAt,
    };
  }

  async getDashboard(tenantId: string) {
    const now = new Date();
    const today = new Date(now);
    today.setHours(0, 0, 0, 0);
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    const [todaysInvoices, monthlyInvoices, totalBills] = await Promise.all([
      this.prisma.invoice.findMany({
        where: { tenantId, deletedAt: null, invoiceDate: { gte: today } },
        select: { grandTotal: true },
      }),
      this.prisma.invoice.findMany({
        where: { tenantId, deletedAt: null, invoiceDate: { gte: monthStart } },
        select: {
          grandTotal: true,
          items: { select: { itemName: true, quantity: true } },
        },
      }),
      this.prisma.invoice.count({ where: { tenantId, deletedAt: null } }),
    ]);

    const todaysRevenue = this.sumDecimals(todaysInvoices, 'grandTotal');
    const monthlyRevenue = this.sumDecimals(monthlyInvoices, 'grandTotal');
    const averageBillValue =
      monthlyInvoices.length === 0
        ? 0
        : monthlyRevenue / monthlyInvoices.length;
    const topSellingMap = new Map<string, number>();

    for (const invoice of monthlyInvoices) {
      for (const item of invoice.items) {
        const name = item.itemName ?? 'Item';
        topSellingMap.set(name, (topSellingMap.get(name) ?? 0) + item.quantity);
      }
    }

    const topSellingProducts = [...topSellingMap.entries()]
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([itemName, quantity]) => ({ itemName, quantity }));

    return {
      todaysRevenue: this.round(todaysRevenue),
      monthlyRevenue: this.round(monthlyRevenue),
      totalBills,
      averageBillValue: this.round(averageBillValue),
      topSellingProducts,
    };
  }

  async findAll(tenantId: string, filters?: InvoiceFilters) {
    return this.prisma.invoice.findMany({
      where: this.buildInvoiceWhere(tenantId, filters),
      orderBy: { createdAt: 'desc' },
      include: {
        customer: { select: { name: true, phone: true } },
        items: {
          select: {
            id: true,
            itemName: true,
            quantity: true,
            grossWeight: true,
            netWeight: true,
            ratePerGram: true,
            metalValue: true,
            makingCharges: true,
            stoneValue: true,
            itemTotal: true,
          },
        },
      },
    });
  }

  async findOne(tenantId: string, id: string) {
    return this.findInvoiceWithDetails(tenantId, id);
  }

  async getPrintableInvoice(tenantId: string, id: string) {
    const [invoice, tenant] = await Promise.all([
      this.findInvoiceWithDetails(tenantId, id),
      this.prisma.tenant.findUnique({
        where: { id: tenantId },
        select: {
          shopName: true,
          ownerName: true,
          phone: true,
          email: true,
          address: true,
          city: true,
          state: true,
          pincode: true,
          gstin: true,
          pan: true,
          logoUrl: true,
        },
      }),
    ]);

    const shopName = tenant?.shopName ?? 'SwarnaLekh';
    const qrPayload = [
      `Invoice:${invoice.invoiceNumber}`,
      `Date:${this.formatDate(invoice.invoiceDate)}`,
      `Amount:${this.toNumber(invoice.grandTotal).toFixed(2)}`,
      `GST:${this.toNumber(invoice.totalTax).toFixed(2)}`,
    ].join('|');
    const verificationCode = this.verificationCode(
      tenantId,
      invoice.invoiceNumber,
      this.toNumber(invoice.grandTotal),
      this.toNumber(invoice.totalTax),
    );

    return {
      shop: {
        name: shopName,
        ownerName: tenant?.ownerName ?? null,
        phone: tenant?.phone ?? null,
        email: tenant?.email ?? null,
        address: tenant?.address ?? null,
        city: tenant?.city ?? null,
        state: tenant?.state ?? null,
        pincode: tenant?.pincode ?? null,
        gstin: tenant?.gstin ?? null,
        pan: tenant?.pan ?? null,
        logoUrl: tenant?.logoUrl ?? null,
      },
      invoice: {
        id: invoice.id,
        invoiceNumber: invoice.invoiceNumber,
        invoiceDate: invoice.invoiceDate,
        customerName: invoice.customerName,
        customerPhone: invoice.customerPhone,
        customerGstin: invoice.customerGstin,
        paymentMode: invoice.paymentMode,
        items: invoice.items.map((item) => ({
          itemName: item.itemName ?? 'Item',
          quantity: item.quantity,
          metalType: item.metalType,
          karat: item.karat,
          grossWeight: this.toNumber(item.grossWeight),
          netWeight: this.toNumber(item.netWeight),
          ratePerGram: this.toNumber(item.ratePerGram),
          metalValue: this.toNumber(item.metalValue),
          makingCharges: this.toNumber(item.makingCharges),
          stoneValue: this.toNumber(item.stoneValue),
          wastageValue: this.toNumber(item.wastageValue),
          hallmarkNumber: item.hallmarkNumber,
          huid: item.huid,
          itemTotal: this.toNumber(item.itemTotal),
        })),
        subtotal: this.toNumber(invoice.subtotal),
        totalMakingCharges: this.toNumber(invoice.totalMakingCharges),
        totalStoneValue: this.toNumber(invoice.totalStoneValue),
        discountAmount: this.toNumber(invoice.discountAmount),
        oldGoldValue: this.toNumber(invoice.oldGoldValue),
        taxableAmount: this.toNumber(invoice.taxableAmount),
        cgstPercent: this.toNumber(invoice.cgstPercent),
        cgstAmount: this.toNumber(invoice.cgstAmount),
        sgstPercent: this.toNumber(invoice.sgstPercent),
        sgstAmount: this.toNumber(invoice.sgstAmount),
        igstPercent: this.toNumber(invoice.igstPercent),
        igstAmount: this.toNumber(invoice.igstAmount),
        totalTax: this.toNumber(invoice.totalTax),
        grandTotal: this.toNumber(invoice.grandTotal),
        roundOff: this.toNumber(invoice.roundOff),
        amountPaid: this.toNumber(invoice.amountPaid),
        balanceDue: this.toNumber(invoice.balanceDue),
        notes: invoice.notes,
        payments: invoice.payments.map((payment) => ({
          id: payment.id,
          amount: this.toNumber(payment.amount),
          paymentMode: payment.paymentMode,
          paymentDate: payment.paymentDate,
          referenceNumber: payment.referenceNumber,
          notes: payment.notes,
        })),
      },
      qrPayload,
      verificationCode,
      generatedAt: new Date().toISOString(),
    } satisfies PrintableInvoice;
  }

  async getInvoicePdf(tenantId: string, id: string) {
    const printable = await this.getPrintableInvoice(tenantId, id);
    const bytes = this.buildInvoicePdf(printable);
    return {
      fileName: `${this.safeFileName(printable.invoice.invoiceNumber)}.pdf`,
      mimeType: 'application/pdf',
      base64: bytes.toString('base64'),
      byteLength: bytes.byteLength,
      verificationCode: printable.verificationCode,
    };
  }

  async getInvoiceShare(tenantId: string, id: string) {
    const printable = await this.getPrintableInvoice(tenantId, id);
    const text = this.buildWhatsAppText(printable);
    return {
      whatsappText: text,
      whatsappUrl: `https://wa.me/?text=${encodeURIComponent(text)}`,
      verificationCode: printable.verificationCode,
    };
  }

  private async findInvoiceWithDetails(tenantId: string, id: string) {
    const invoice = await this.prisma.invoice.findFirst({
      where: { id, tenantId, deletedAt: null },
      include: invoiceDetailInclude,
    });

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }
    return invoice;
  }

  private buildWhatsAppText(printable: PrintableInvoice) {
    const invoice = printable.invoice;
    return [
      `${printable.shop.name} Invoice`,
      `Invoice No: ${invoice.invoiceNumber}`,
      `Date: ${this.formatDate(invoice.invoiceDate)}`,
      `Customer: ${invoice.customerName ?? 'Walk-in Customer'}`,
      `Amount: ${this.formatMoney(invoice.grandTotal)}`,
      `Paid: ${this.formatMoney(invoice.amountPaid)}`,
      `Balance: ${this.formatMoney(invoice.balanceDue)}`,
      `Payment: ${invoice.paymentMode ?? 'Not recorded'}`,
      `GST: ${this.formatMoney(invoice.totalTax)}`,
      `Verification: ${printable.verificationCode}`,
    ].join('\n');
  }

  private buildInvoicePdf(printable: PrintableInvoice) {
    const invoice = printable.invoice;
    const logo = this.embeddableLogo(printable.shop.logoUrl);
    const shopAddress = [
      printable.shop.address,
      printable.shop.city,
      printable.shop.state,
      printable.shop.pincode,
    ]
      .filter(Boolean)
      .join(', ');
    const lines = [
      printable.shop.name,
      shopAddress,
      printable.shop.phone ? `Phone: ${printable.shop.phone}` : '',
      printable.shop.email ? `Email: ${printable.shop.email}` : '',
      printable.shop.gstin ? `GSTIN: ${printable.shop.gstin}` : '',
      logo ? 'Shop Logo: Embedded' : '',
      '',
      'TAX INVOICE',
      `Invoice No: ${invoice.invoiceNumber}`,
      `Invoice Date: ${this.formatDate(invoice.invoiceDate)}`,
      `Customer: ${invoice.customerName ?? 'Walk-in Customer'}`,
      invoice.customerPhone ? `Mobile: ${invoice.customerPhone}` : '',
      invoice.customerGstin ? `Customer GSTIN: ${invoice.customerGstin}` : '',
      '',
      'Product Details',
      'Item | Purity | Gross | Net | Rate | Making | GST Base | Total',
      ...invoice.items.map((item) =>
        [
          item.itemName,
          item.karat ?? '-',
          `${item.grossWeight.toFixed(3)}g`,
          `${item.netWeight.toFixed(3)}g`,
          this.formatPdfMoney(item.ratePerGram),
          this.formatPdfMoney(item.makingCharges),
          this.formatPdfMoney(item.itemTotal),
          this.formatPdfMoney(item.itemTotal),
        ].join(' | '),
      ),
      '',
      'GST Breakdown',
      `Taxable Amount: ${this.formatPdfMoney(invoice.taxableAmount)}`,
      `CGST (${invoice.cgstPercent}%): ${this.formatPdfMoney(invoice.cgstAmount)}`,
      `SGST (${invoice.sgstPercent}%): ${this.formatPdfMoney(invoice.sgstAmount)}`,
      `IGST (${invoice.igstPercent}%): ${this.formatPdfMoney(invoice.igstAmount)}`,
      `Total GST: ${this.formatPdfMoney(invoice.totalTax)}`,
      '',
      'Bill Summary',
      `Subtotal: ${this.formatPdfMoney(invoice.subtotal)}`,
      `Making Charges: ${this.formatPdfMoney(invoice.totalMakingCharges)}`,
      `Stone Value: ${this.formatPdfMoney(invoice.totalStoneValue)}`,
      `Discount: ${this.formatPdfMoney(invoice.discountAmount)}`,
      `Old Gold Exchange: ${this.formatPdfMoney(invoice.oldGoldValue)}`,
      `Round Off: ${this.formatPdfMoney(invoice.roundOff)}`,
      `Final Total: ${this.formatPdfMoney(invoice.grandTotal)}`,
      `Amount Paid: ${this.formatPdfMoney(invoice.amountPaid)}`,
      `Balance Due: ${this.formatPdfMoney(invoice.balanceDue)}`,
      `Payment Method: ${invoice.paymentMode ?? 'Not recorded'}`,
      '',
      'Invoice Protection',
      `Verification Code: ${printable.verificationCode}`,
      `QR Payload: ${printable.qrPayload}`,
      printable.generatedAt ? `Generated At: ${printable.generatedAt}` : '',
      '',
      invoice.notes ? `Notes: ${invoice.notes}` : '',
      'Thank you for shopping with us.',
    ].filter((line) => line.trim().length > 0);

    return this.renderTextPdf(lines, logo);
  }

  private renderTextPdf(lines: string[], logo?: PdfLogoImage | null) {
    const pageWidth = 595;
    const pageHeight = 842;
    const left = 40;
    const top = 802;
    const lineHeight = 14;

    const objects: string[] = [];
    const addObject = (body: string) => {
      objects.push(body);
      return objects.length;
    };

    const catalogId = addObject('<< /Type /Catalog /Pages 2 0 R >>');
    const pagesId = addObject('');
    const fontId = addObject(
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    );
    const logoId = logo
      ? addObject(
          [
            '<< /Type /XObject /Subtype /Image',
            `/Width ${logo.width}`,
            `/Height ${logo.height}`,
            '/ColorSpace /DeviceRGB',
            '/BitsPerComponent 8',
            '/Filter [/ASCIIHexDecode /DCTDecode]',
            `/Length ${logo.bytes.toString('hex').length + 1}`,
            '>>',
            'stream',
            `${logo.bytes.toString('hex').toUpperCase()}>`,
            'endstream',
          ].join('\n'),
        )
      : null;
    const pageIds: number[] = [];
    let lineIndex = 0;
    let pageIndex = 0;

    while (lineIndex < lines.length || pageIndex === 0) {
      const hasPageLogo = Boolean(pageIndex === 0 && logo && logoId);
      const logoDrawWidth = hasPageLogo ? 64 : 0;
      const logoDrawHeight =
        hasPageLogo && logo!.width > 0
          ? Math.min(64, (logo!.height / logo!.width) * logoDrawWidth)
          : 0;
      const textTop = hasPageLogo ? top - logoDrawHeight - 18 : top;
      const maxLines = Math.max(1, Math.floor((textTop - 40) / lineHeight));
      const pageLines = lines.slice(lineIndex, lineIndex + maxLines);
      lineIndex += pageLines.length;

      const imageOps = hasPageLogo
        ? [
            'q',
            `${logoDrawWidth} 0 0 ${logoDrawHeight.toFixed(2)} ${left} ${(top - logoDrawHeight).toFixed(2)} cm`,
            '/Logo Do',
            'Q',
          ]
        : [];
      const textOps = pageLines.length
        ? [
            'BT',
            '/F1 9 Tf',
            `${left} ${textTop.toFixed(2)} Td`,
            `${lineHeight} TL`,
            ...pageLines.flatMap((line, index) => {
              const text = `(${this.escapePdfText(this.truncatePdfLine(line))}) Tj`;
              return index === 0 ? [text] : ['T*', text];
            }),
            'ET',
          ]
        : [];
      const stream = [...imageOps, ...textOps].join('\n');
      const resources = [
        `/Font << /F1 ${fontId} 0 R >>`,
        logoId ? `/XObject << /Logo ${logoId} 0 R >>` : '',
      ]
        .filter(Boolean)
        .join(' ');
      const contentId = addObject(
        `<< /Length ${Buffer.byteLength(stream, 'utf8')} >>\nstream\n${stream}\nendstream`,
      );
      const pageId = addObject(
        [
          '<< /Type /Page',
          `/Parent ${pagesId} 0 R`,
          `/MediaBox [0 0 ${pageWidth} ${pageHeight}]`,
          `/Resources << ${resources} >>`,
          `/Contents ${contentId} 0 R`,
          '>>',
        ].join(' '),
      );
      pageIds.push(pageId);
      pageIndex += 1;
    }

    objects[pagesId - 1] =
      `<< /Type /Pages /Kids [${pageIds.map((id) => `${id} 0 R`).join(' ')}] /Count ${pageIds.length} >>`;

    const parts = ['%PDF-1.4\n'];
    const offsets = [0];
    for (let index = 0; index < objects.length; index += 1) {
      offsets.push(Buffer.byteLength(parts.join(''), 'utf8'));
      parts.push(`${index + 1} 0 obj\n${objects[index]}\nendobj\n`);
    }
    const xrefOffset = Buffer.byteLength(parts.join(''), 'utf8');
    parts.push(`xref\n0 ${objects.length + 1}\n`);
    parts.push('0000000000 65535 f \n');
    for (const offset of offsets.slice(1)) {
      parts.push(`${offset.toString().padStart(10, '0')} 00000 n \n`);
    }
    parts.push(
      [
        'trailer',
        `<< /Size ${objects.length + 1} /Root ${catalogId} 0 R >>`,
        'startxref',
        xrefOffset.toString(),
        '%%EOF',
      ].join('\n'),
    );

    return Buffer.from(parts.join(''), 'utf8');
  }

  private embeddableLogo(value: string | null) {
    if (!value) return null;

    const match = /^data:image\/jpe?g;base64,([\s\S]+)$/i.exec(value.trim());
    if (!match) return null;

    try {
      const bytes = Buffer.from(match[1], 'base64');
      const size = this.jpegSize(bytes);
      return size ? { bytes, ...size } : null;
    } catch {
      return null;
    }
  }

  private jpegSize(bytes: Buffer) {
    if (bytes.length < 4 || bytes[0] !== 0xff || bytes[1] !== 0xd8) {
      return null;
    }

    let offset = 2;
    while (offset + 9 < bytes.length) {
      if (bytes[offset] !== 0xff) {
        offset += 1;
        continue;
      }

      const marker = bytes[offset + 1];
      offset += 2;

      if (marker === 0xd8 || marker === 0xd9) continue;
      if (marker === 0xda) break;
      if (offset + 2 > bytes.length) break;

      const length = bytes.readUInt16BE(offset);
      if (length < 2 || offset + length > bytes.length) break;

      const isStartOfFrame =
        (marker >= 0xc0 && marker <= 0xc3) ||
        (marker >= 0xc5 && marker <= 0xc7) ||
        (marker >= 0xc9 && marker <= 0xcb) ||
        (marker >= 0xcd && marker <= 0xcf);

      if (isStartOfFrame) {
        return {
          height: bytes.readUInt16BE(offset + 3),
          width: bytes.readUInt16BE(offset + 5),
        };
      }

      offset += length;
    }

    return null;
  }

  private escapePdfText(value: string) {
    return value
      .replace(/[^\x20-\x7E]/g, ' ')
      .replace(/\\/g, '\\\\')
      .replace(/\(/g, '\\(')
      .replace(/\)/g, '\\)');
  }

  private truncatePdfLine(value: string) {
    return value.length > 116 ? `${value.slice(0, 113)}...` : value;
  }

  private verificationCode(
    tenantId: string,
    invoiceNumber: string,
    grandTotal: number,
    totalTax: number,
  ) {
    return createHash('sha256')
      .update(`${tenantId}:${invoiceNumber}:${grandTotal}:${totalTax}`)
      .digest('hex')
      .slice(0, 12)
      .toUpperCase();
  }

  private safeFileName(value: string) {
    return value.replace(/[^a-z0-9-]+/gi, '-').replace(/^-+|-+$/g, '');
  }

  private formatDate(value: Date) {
    return value.toISOString().slice(0, 10);
  }

  private formatMoney(value: number) {
    return `₹${value.toFixed(2)}`;
  }

  private formatPdfMoney(value: number) {
    return `Rs. ${value.toFixed(2)}`;
  }

  private buildInvoiceWhere(
    tenantId: string,
    filters?: InvoiceFilters,
  ): Prisma.InvoiceWhereInput {
    const search = filters?.search?.trim();
    const dateFrom = this.parseDate(filters?.dateFrom);
    const dateTo = this.parseDate(filters?.dateTo, true);
    const invoiceDate: Prisma.DateTimeFilter = {};
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
          { customerPhone: { contains: search, mode: 'insensitive' } },
        ],
      }),
    };
  }

  private parseDate(value?: string, endOfDay = false) {
    if (!value) return null;
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return null;
    if (endOfDay) date.setUTCHours(23, 59, 59, 999);
    return date;
  }

  private explicitSellingPriceBreakdown(input: {
    lineTotal: number;
    netWeight: number;
    componentRatePerGram: number;
    makingCharges: number;
    stoneValue: number;
    wastagePercent: number;
  }) {
    const itemTotal = this.round(input.lineTotal);
    const makingCharges = this.round(input.makingCharges);
    const stoneValue = this.round(input.stoneValue);
    const metalValueAtRate =
      input.componentRatePerGram > 0
        ? this.round(input.netWeight * input.componentRatePerGram)
        : 0;
    const wastageValue =
      metalValueAtRate > 0
        ? this.round(
            (metalValueAtRate * Math.max(0, input.wastagePercent)) / 100,
          )
        : 0;
    const metalValue = this.round(
      Math.max(0, itemTotal - makingCharges - stoneValue - wastageValue),
    );

    return {
      metalValue,
      makingCharges,
      stoneValue,
      wastageValue,
      itemTotal,
    };
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

  private sumDecimals<T extends Record<string, unknown>>(
    rows: T[],
    key: keyof T,
  ) {
    return rows.reduce((sum, row) => sum + this.toNumber(row[key]), 0);
  }

  private round(value: number) {
    return Number(value.toFixed(2));
  }
}
