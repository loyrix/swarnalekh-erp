import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreateInvoiceDto } from './invoice.dto.js';
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
  };
  qrPayload: string;
  verificationCode: string;
  generatedAt: string;
};

@Injectable()
export class InvoiceService {
  constructor(private readonly prisma: PrismaService) {}

  async createInvoice(tenantId: string, userId: string, dto: CreateInvoiceDto) {
    return this.prisma.$transaction(async (tx) => {
      // 1. Generate Invoice Number
      const year = new Date().getFullYear();
      const startOfYear = new Date(year, 0, 1);

      const count = await tx.invoice.count({
        where: {
          tenantId,
          createdAt: { gte: startOfYear },
        },
      });
      const prefix = `SLK-${year}`;
      const invoiceNumber = `${prefix}-${String(count + 1).padStart(4, '0')}`;

      // 2. Fetch Customer info
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

      // 3. Process Items & Calculate Totals
      let subtotal = new Prisma.Decimal(0);
      let totalMakingCharges = new Prisma.Decimal(0);
      let totalStoneValue = new Prisma.Decimal(0);

      const invoiceItemsInput = [];

      for (const itemDto of dto.items) {
        // Fetch inventory item
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

        const requestedQuantity = Math.max(
          1,
          Math.floor(itemDto.quantity ?? 1),
        );
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

        const explicitSellingPricePerPiece = this.toNumber(
          invItem.sellingPrice,
        );
        const hasExplicitSellingPrice = explicitSellingPricePerPiece > 0;
        const rateRecord = hasExplicitSellingPrice
          ? null
          : ((await tx.dailyRate.findFirst({
              where: {
                tenantId,
                metalType: { equals: invItem.metalType, mode: 'insensitive' },
                karat: invItem.karat ?? null,
              },
              orderBy: [{ rateDate: 'desc' }, { createdAt: 'desc' }],
            })) ??
            (await tx.dailyRate.findFirst({
              where: {
                tenantId,
                metalType: { equals: invItem.metalType, mode: 'insensitive' },
                karat: null,
              },
              orderBy: [{ rateDate: 'desc' }, { createdAt: 'desc' }],
            })));

        if (!hasExplicitSellingPrice && !rateRecord) {
          throw new BadRequestException(
            `No rate set for ${invItem.metalType} ${invItem.karat || ''}. Please set rates first.`,
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

        invoiceItemsInput.push({
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
        });

        if (invItem.stockType === 'bulk') {
          const remainingQuantity = availableQuantity - requestedQuantity;
          await tx.inventoryItem.update({
            where: { id: invItem.id },
            data: {
              quantity: remainingQuantity,
              status: remainingQuantity > 0 ? 'in_stock' : 'sold',
            },
          });
        } else {
          await tx.inventoryItem.update({
            where: { id: invItem.id },
            data: { status: 'sold' },
          });
        }
      }

      // 4. Handle Old Gold Exchange
      let oldGoldValue = 0;
      if (dto.oldGoldWeight && dto.oldGoldRate) {
        oldGoldValue = calculateOldGoldValue(
          dto.oldGoldWeight,
          dto.oldGoldRate,
        );
      }

      // 5. Calculate Taxes & Final Grand Total
      const totals = calculateInvoiceTotals({
        itemTotals: invoiceItemsInput.map((item) => item.itemTotal.toNumber()),
        discountAmount: dto.discountAmount || 0,
        oldGoldValue,
      });

      // 6. Create Invoice
      const invoice = await tx.invoice.create({
        data: {
          tenantId,
          invoiceNumber,
          customerId: dto.customerId,
          customerName,
          customerPhone,
          subtotal,
          totalMakingCharges,
          totalStoneValue,
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
          items: {
            create: invoiceItemsInput,
          },
        },
        include: { items: true },
      });

      // 7. Create Payment record if amountPaid > 0
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

      // 8. Update Customer Stats
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

    return this.renderTextPdf(lines);
  }

  private renderTextPdf(lines: string[]) {
    const pageWidth = 595;
    const pageHeight = 842;
    const left = 40;
    const top = 802;
    const lineHeight = 14;
    const maxLines = Math.floor((top - 40) / lineHeight);
    const pages: string[] = [];

    for (let index = 0; index < lines.length; index += maxLines) {
      const pageLines = lines.slice(index, index + maxLines);
      const stream = [
        'BT',
        '/F1 9 Tf',
        `${left} ${top} Td`,
        `${lineHeight} TL`,
        ...pageLines.flatMap((line, lineIndex) => {
          const text = `(${this.escapePdfText(this.truncatePdfLine(line))}) Tj`;
          return lineIndex === 0 ? [text] : ['T*', text];
        }),
        'ET',
      ].join('\n');
      pages.push(stream);
    }

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
    const pageIds: number[] = [];

    for (const stream of pages) {
      const contentId = addObject(
        `<< /Length ${Buffer.byteLength(stream, 'utf8')} >>\nstream\n${stream}\nendstream`,
      );
      const pageId = addObject(
        [
          '<< /Type /Page',
          `/Parent ${pagesId} 0 R`,
          `/MediaBox [0 0 ${pageWidth} ${pageHeight}]`,
          `/Resources << /Font << /F1 ${fontId} 0 R >> >>`,
          `/Contents ${contentId} 0 R`,
          '>>',
        ].join(' '),
      );
      pageIds.push(pageId);
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
    if (endOfDay) date.setHours(23, 59, 59, 999);
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
