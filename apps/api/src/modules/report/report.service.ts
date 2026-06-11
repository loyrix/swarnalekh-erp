import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import {
  calculateItemPrice,
  calculateMortgagePayable,
} from '@swarnbook/business-logic';
import { PrismaService } from '../../prisma/prisma.service.js';
import { ReportQueryDto } from './report.dto.js';

export const REPORT_TYPES = [
  'current-stock',
  'sold-products',
  'low-stock',
  'daily-sales',
  'monthly-sales',
  'gst',
  'active-loans',
  'interest-collection',
  'closed-loans',
] as const;

export type ReportType = (typeof REPORT_TYPES)[number];

const REPORT_LABELS: Record<ReportType, string> = {
  'current-stock': 'Current Stock Report',
  'sold-products': 'Sold Products Report',
  'low-stock': 'Low Stock Report',
  'daily-sales': 'Daily Sales Report',
  'monthly-sales': 'Monthly Sales Report',
  gst: 'GST Report',
  'active-loans': 'Active Loans Report',
  'interest-collection': 'Interest Collection Report',
  'closed-loans': 'Closed Loans Report',
};

const REPORT_COLUMNS: Record<
  ReportType,
  Array<{ label: string; key: string }>
> = {
  'current-stock': [
    { label: 'Product Name', key: 'itemName' },
    { label: 'Design Number', key: 'designNumber' },
    { label: 'Category', key: 'categoryName' },
    { label: 'Purity', key: 'purity' },
    { label: 'Gross Weight', key: 'grossWeight' },
    { label: 'Net Weight', key: 'netWeight' },
    { label: 'Selling Price', key: 'estimatedSellingPrice' },
    { label: 'Stock Status', key: 'status' },
    { label: 'Branch', key: 'location' },
  ],
  'sold-products': [
    { label: 'Invoice Number', key: 'invoiceNumber' },
    { label: 'Customer Name', key: 'customerName' },
    { label: 'Product Name', key: 'productName' },
    { label: 'Sold Date', key: 'soldDate' },
    { label: 'Selling Price', key: 'sellingPrice' },
    { label: 'Payment Method', key: 'paymentMode' },
  ],
  'low-stock': [
    { label: 'Product Name', key: 'itemName' },
    { label: 'Design Number', key: 'designNumber' },
    { label: 'Category', key: 'categoryName' },
    { label: 'Available Qty', key: 'quantity' },
    { label: 'Purity', key: 'purity' },
    { label: 'Branch', key: 'location' },
  ],
  'daily-sales': [
    { label: 'Invoice Number', key: 'invoiceNumber' },
    { label: 'Customer Name', key: 'customerName' },
    { label: 'Date', key: 'invoiceDate' },
    { label: 'Total', key: 'grandTotal' },
    { label: 'Payment', key: 'paymentMode' },
    { label: 'Items', key: 'itemCount' },
  ],
  'monthly-sales': [
    { label: 'Invoice Number', key: 'invoiceNumber' },
    { label: 'Customer Name', key: 'customerName' },
    { label: 'Date', key: 'invoiceDate' },
    { label: 'Total', key: 'grandTotal' },
    { label: 'Payment', key: 'paymentMode' },
    { label: 'Items', key: 'itemCount' },
  ],
  gst: [
    { label: 'Invoice Number', key: 'invoiceNumber' },
    { label: 'Customer Name', key: 'customerName' },
    { label: 'Taxable', key: 'taxableAmount' },
    { label: 'CGST', key: 'cgstAmount' },
    { label: 'SGST', key: 'sgstAmount' },
    { label: 'Total GST', key: 'totalTax' },
  ],
  'active-loans': [
    { label: 'Customer Name', key: 'customerName' },
    { label: 'Loan Number', key: 'loanNumber' },
    { label: 'Loan Amount', key: 'principalAmount' },
    { label: 'Pending Interest', key: 'pendingInterestAmount' },
    { label: 'Payable', key: 'totalPayableAmount' },
    { label: 'Next Due', key: 'nextDueDate' },
  ],
  'interest-collection': [
    { label: 'Receipt Number', key: 'receiptNumber' },
    { label: 'Customer Name', key: 'customerName' },
    { label: 'Loan Number', key: 'loanNumber' },
    { label: 'Date', key: 'paymentDate' },
    { label: 'Amount', key: 'amount' },
    { label: 'Payment Method', key: 'paymentMode' },
  ],
  'closed-loans': [
    { label: 'Customer Name', key: 'customerName' },
    { label: 'Loan Number', key: 'loanNumber' },
    { label: 'Loan Amount', key: 'principalAmount' },
    { label: 'Interest Paid', key: 'totalInterestPaid' },
    { label: 'Closing Date', key: 'closedAt' },
    { label: 'Loan Status', key: 'status' },
  ],
};

@Injectable()
export class ReportService {
  constructor(private readonly prisma: PrismaService) {}

  async getOverview(tenantId: string, filters: ReportQueryDto = {}) {
    const [inventoryItems, invoices, mortgageLoans] = await Promise.all([
      this.getInventoryItems(tenantId, filters),
      this.getInvoices(tenantId, filters),
      this.getMortgageLoans(tenantId, filters),
    ]);

    const currentStock = inventoryItems
      .filter((item) => item.status !== 'sold')
      .map((item) => this.toInventoryRow(item));
    const lowStock = currentStock.filter((item) => {
      return item.stockType === 'bulk' && item.quantity <= 2;
    });
    const soldProducts = invoices.flatMap((invoice) =>
      invoice.items.map((item: any) => ({
        invoiceNumber: invoice.invoiceNumber,
        customerName: invoice.customerName,
        customerPhone: invoice.customerPhone,
        productName: item.itemName ?? 'Product',
        soldDate: invoice.invoiceDate,
        sellingPrice: this.round(this.toNumber(item.itemTotal)),
        paymentMode: invoice.paymentMode,
      })),
    );

    const reportDate = this.parseDate(filters.dateFrom) ?? new Date();
    const dailySales = invoices
      .filter((invoice) => this.isSameDay(invoice.invoiceDate, reportDate))
      .map((invoice) => this.toInvoiceRow(invoice));
    const monthlySales = invoices
      .filter((invoice) => this.isSameMonth(invoice.invoiceDate, reportDate))
      .map((invoice) => this.toInvoiceRow(invoice));
    const gst = invoices.map((invoice) => this.toInvoiceRow(invoice));
    const loanRows = mortgageLoans.map((loan) => this.toLoanRow(loan));
    const activeLoans = loanRows.filter(
      (loan) =>
        loan.status === 'active' &&
        this.passesDateRange(loan.loanDate, filters),
    );
    const closedLoans = loanRows.filter(
      (loan) =>
        loan.status === 'closed' &&
        this.passesDateRange(loan.closedAt, filters),
    );
    const interestCollection = this.toInterestCollectionRows(
      mortgageLoans,
    ).filter((payment) => this.passesDateRange(payment.paymentDate, filters));

    return {
      generatedAt: new Date().toISOString(),
      filters: this.cleanFilters(filters),
      inventoryStats: this.inventoryStats(currentStock),
      reports: {
        currentStock,
        soldProducts,
        lowStock,
        dailySales,
        monthlySales,
        gst,
        activeLoans,
        interestCollection,
        closedLoans,
      },
      summary: {
        inventory: {
          currentStockCount: currentStock.length,
          soldProductsCount: soldProducts.length,
          lowStockCount: lowStock.length,
        },
        billing: {
          dailySalesTotal: this.sum(dailySales, 'grandTotal'),
          monthlySalesTotal: this.sum(monthlySales, 'grandTotal'),
          gstTotal: this.sum(gst, 'totalTax'),
        },
        mortgage: {
          activeLoansCount: activeLoans.length,
          interestCollectionTotal: this.sum(interestCollection, 'amount'),
          closedLoansCount: closedLoans.length,
        },
      },
    };
  }

  async getExport(
    tenantId: string,
    type: string,
    filters: ReportQueryDto = {},
  ) {
    if (!this.isReportType(type)) {
      throw new BadRequestException('Unsupported report type');
    }

    const overview = await this.getOverview(tenantId, filters);
    const rows = this.rowsForType(overview.reports, type);
    const title = REPORT_LABELS[type];
    const pdf = this.buildReportPdf(title, rows, REPORT_COLUMNS[type], filters);

    return {
      reportType: type,
      title,
      fileName: `${type}-${this.formatDate(new Date())}.pdf`,
      mimeType: 'application/pdf',
      rowCount: rows.length,
      base64: pdf.toString('base64'),
    };
  }

  private async getInventoryItems(tenantId: string, filters: ReportQueryDto) {
    const search = this.clean(filters.search);
    const categoryName = this.clean(filters.categoryName);
    const branch = this.clean(filters.branch);
    const status = this.clean(filters.status);

    return this.prisma.inventoryItem.findMany({
      where: {
        tenantId,
        deletedAt: null,
        ...(status && status !== 'all' ? { status } : {}),
        ...(branch
          ? { location: { contains: branch, mode: 'insensitive' } }
          : {}),
        ...(categoryName
          ? {
              category: {
                name: { contains: categoryName, mode: 'insensitive' },
              },
            }
          : {}),
        ...(search
          ? {
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
            }
          : {}),
      },
      include: { category: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  private async getInvoices(tenantId: string, filters: ReportQueryDto) {
    const search = this.clean(filters.search);
    const invoiceDate: Prisma.DateTimeFilter = {};
    const dateFrom = this.parseDate(filters.dateFrom);
    const dateTo = this.parseDate(filters.dateTo, true);
    if (dateFrom) invoiceDate.gte = dateFrom;
    if (dateTo) invoiceDate.lte = dateTo;

    return this.prisma.invoice.findMany({
      where: {
        tenantId,
        deletedAt: null,
        ...((invoiceDate.gte || invoiceDate.lte) && { invoiceDate }),
        ...(search
          ? {
              OR: [
                { invoiceNumber: { contains: search, mode: 'insensitive' } },
                { customerName: { contains: search, mode: 'insensitive' } },
                { customerPhone: { contains: search, mode: 'insensitive' } },
                {
                  items: {
                    some: {
                      itemName: { contains: search, mode: 'insensitive' },
                    },
                  },
                },
              ],
            }
          : {}),
      },
      include: {
        items: true,
      },
      orderBy: [{ invoiceDate: 'desc' }, { createdAt: 'desc' }],
    });
  }

  private async getMortgageLoans(tenantId: string, filters: ReportQueryDto) {
    const search = this.clean(filters.search);
    const status = this.clean(filters.status);

    return this.prisma.mortgageLoan.findMany({
      where: {
        tenantId,
        deletedAt: null,
        ...(status && status !== 'all' ? { status } : {}),
        ...(search
          ? {
              OR: [
                { loanNumber: { contains: search, mode: 'insensitive' } },
                { customerName: { contains: search, mode: 'insensitive' } },
                { customerPhone: { contains: search } },
                {
                  payments: {
                    some: {
                      receiptNumber: { contains: search, mode: 'insensitive' },
                    },
                  },
                },
              ],
            }
          : {}),
      },
      include: {
        payments: {
          orderBy: [
            { paymentDate: 'desc' as const },
            { createdAt: 'desc' as const },
          ],
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  private toInventoryRow(item: any) {
    const quantity = item.quantity || 1;
    const grossWeight = this.toNumber(item.grossWeight);
    const netWeight = this.toNumber(item.netWeight);
    const sellingPrice = this.inventorySellingPrice(item);

    return {
      id: item.id,
      itemName: item.itemName,
      productName: item.itemName,
      tagNumber: item.tagNumber,
      barcode: item.barcode,
      productCode: item.tagNumber ?? item.barcode,
      designNumber: item.barcode,
      categoryName: item.category?.name ?? null,
      metalType: item.metalType,
      purity: item.karat ?? item.purity,
      karat: item.karat,
      grossWeight,
      netWeight,
      totalGrossWeight: this.round(grossWeight * quantity, 3),
      totalNetWeight: this.round(netWeight * quantity, 3),
      quantity,
      stockType: item.stockType,
      status: item.status,
      location: item.location,
      sellingPrice,
      estimatedSellingPrice: sellingPrice,
      estimatedTotalValue:
        sellingPrice == null ? null : this.round(sellingPrice * quantity),
    };
  }

  private toInvoiceRow(invoice: any) {
    const items = (invoice.items ?? []).map((item: any) => ({
      id: item.id,
      itemName: item.itemName,
      quantity: item.quantity,
      grossWeight: this.toNumber(item.grossWeight),
      netWeight: this.toNumber(item.netWeight),
      ratePerGram: this.toNumber(item.ratePerGram),
      metalValue: this.toNumber(item.metalValue),
      makingCharges: this.toNumber(item.makingCharges),
      stoneValue: this.toNumber(item.stoneValue),
      itemTotal: this.toNumber(item.itemTotal),
    }));

    return {
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      invoiceDate: invoice.invoiceDate,
      customerName: invoice.customerName,
      customerPhone: invoice.customerPhone,
      paymentMode: invoice.paymentMode,
      itemCount: items.length,
      items,
      taxableAmount: this.round(this.toNumber(invoice.taxableAmount)),
      cgstAmount: this.round(this.toNumber(invoice.cgstAmount)),
      sgstAmount: this.round(this.toNumber(invoice.sgstAmount)),
      igstAmount: this.round(this.toNumber(invoice.igstAmount)),
      totalTax: this.round(this.toNumber(invoice.totalTax)),
      grandTotal: this.round(this.toNumber(invoice.grandTotal)),
    };
  }

  private toLoanRow(loan: any) {
    const snapshot = calculateMortgagePayable({
      principalAmount: this.toNumber(loan.principalAmount),
      interestRateMonthly: this.toNumber(loan.interestRateMonthly),
      loanDate: loan.loanDate,
      interestPaid: this.toNumber(loan.totalInterestPaid),
      principalPaid: this.toNumber(loan.totalPrincipalPaid),
    });
    const isClosed = loan.status === 'closed';

    return {
      id: loan.id,
      loanNumber: loan.loanNumber,
      customerName: loan.customerName,
      customerPhone: loan.customerPhone,
      loanDate: loan.loanDate,
      principalAmount: this.round(this.toNumber(loan.principalAmount)),
      pendingInterestAmount: isClosed
        ? 0
        : this.round(snapshot.pendingInterestAmount),
      totalPayableAmount: isClosed
        ? 0
        : this.round(snapshot.totalPayableAmount),
      nextDueDate: isClosed ? null : snapshot.nextDueDate,
      totalInterestPaid: this.round(this.toNumber(loan.totalInterestPaid)),
      status: loan.status,
      closedAt: loan.closedAt,
    };
  }

  private toInterestCollectionRows(loans: any[]) {
    return loans.flatMap((loan) =>
      (loan.payments ?? [])
        .filter((payment: any) => payment.paymentType !== 'principal')
        .map((payment: any) => ({
          id: payment.id,
          receiptNumber: payment.receiptNumber,
          paymentDate: payment.paymentDate,
          customerName: loan.customerName,
          customerPhone: loan.customerPhone,
          loanNumber: loan.loanNumber,
          amount: this.round(this.toNumber(payment.amount)),
          paymentMode: payment.paymentMode,
          paymentType: payment.paymentType,
        })),
    );
  }

  private inventoryStats(currentStock: any[]) {
    return {
      totalGoldWeight: this.round(
        currentStock
          .filter((item) => String(item.metalType).toLowerCase() === 'gold')
          .reduce((sum, item) => sum + this.toNumber(item.totalNetWeight), 0),
        3,
      ),
      totalSilverWeight: this.round(
        currentStock
          .filter((item) => String(item.metalType).toLowerCase() === 'silver')
          .reduce((sum, item) => sum + this.toNumber(item.totalNetWeight), 0),
        3,
      ),
      totalProducts: currentStock.length,
    };
  }

  private inventorySellingPrice(item: any) {
    if (item.sellingPrice != null)
      return this.round(this.toNumber(item.sellingPrice));
    const ratePerGram = this.toNumber(item.purchaseRate);
    if (ratePerGram <= 0) return null;
    const makingCharges = this.calculateMakingCharges(item, ratePerGram);
    const price = calculateItemPrice({
      netWeight: this.toNumber(item.netWeight),
      ratePerGram,
      makingCharges,
      stoneValue: this.toNumber(item.stoneValue),
      wastagePercent: this.toNumber(item.wastagePercent),
    });
    return this.round(price.itemTotal);
  }

  private calculateMakingCharges(item: any, ratePerGram: number | null) {
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

  private rowsForType(reports: any, type: ReportType): any[] {
    return (
      {
        'current-stock': reports.currentStock,
        'sold-products': reports.soldProducts,
        'low-stock': reports.lowStock,
        'daily-sales': reports.dailySales,
        'monthly-sales': reports.monthlySales,
        gst: reports.gst,
        'active-loans': reports.activeLoans,
        'interest-collection': reports.interestCollection,
        'closed-loans': reports.closedLoans,
      } satisfies Record<ReportType, any[]>
    )[type];
  }

  private buildReportPdf(
    title: string,
    rows: any[],
    columns: Array<{ label: string; key: string }>,
    filters: ReportQueryDto,
  ) {
    const lines = [
      'SwarnaLekh',
      title,
      `Generated: ${this.formatDate(new Date())}`,
      `Filters: ${this.filterSummary(filters)}`,
      `Rows: ${rows.length}`,
      '',
      columns.map((column) => column.label).join(' | '),
      '-'.repeat(110),
      ...rows.map((row) =>
        columns
          .map((column) => this.formatPdfCell(row[column.key]))
          .join(' | '),
      ),
    ];

    if (rows.length === 0) lines.push('No rows found.');
    return this.buildPdf(lines);
  }

  private buildPdf(lines: string[]) {
    const pageWidth = 595;
    const pageHeight = 842;
    const margin = 42;
    const lineHeight = 14;
    const maxLinesPerPage = Math.floor((pageHeight - margin * 2) / lineHeight);
    const pages: string[] = [];

    for (let start = 0; start < lines.length; start += maxLinesPerPage) {
      const chunk = lines.slice(start, start + maxLinesPerPage);
      const commands = [
        'BT',
        '/F1 10 Tf',
        `1 0 0 1 ${margin} ${pageHeight - margin} Tm`,
      ];
      chunk.forEach((line, index) => {
        if (index > 0) commands.push(`0 -${lineHeight} Td`);
        commands.push(`(${this.escapePdfText(this.truncatePdfLine(line))}) Tj`);
      });
      commands.push('ET');
      pages.push(commands.join('\n'));
    }

    const objects: string[] = [];
    const addObject = (value: string) => {
      objects.push(value);
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

  private filterSummary(filters: ReportQueryDto) {
    const parts = [
      this.clean(filters.search) ? `Search=${this.clean(filters.search)}` : '',
      this.clean(filters.dateFrom)
        ? `From=${this.clean(filters.dateFrom)}`
        : '',
      this.clean(filters.dateTo) ? `To=${this.clean(filters.dateTo)}` : '',
      this.clean(filters.categoryName)
        ? `Category=${this.clean(filters.categoryName)}`
        : '',
      this.clean(filters.branch) ? `Branch=${this.clean(filters.branch)}` : '',
      this.clean(filters.status) ? `Status=${this.clean(filters.status)}` : '',
    ].filter(Boolean);
    return parts.length === 0 ? 'All' : parts.join(', ');
  }

  private cleanFilters(filters: ReportQueryDto) {
    return {
      search: this.clean(filters.search),
      dateFrom: this.clean(filters.dateFrom),
      dateTo: this.clean(filters.dateTo),
      categoryName: this.clean(filters.categoryName),
      branch: this.clean(filters.branch),
      status: this.clean(filters.status),
    };
  }

  private passesDateRange(value: unknown, filters: ReportQueryDto) {
    const date = this.asDate(value);
    if (!date) return true;
    const from = this.parseDate(filters.dateFrom);
    const to = this.parseDate(filters.dateTo, true);
    if (from && date < from) return false;
    if (to && date > to) return false;
    return true;
  }

  private parseDate(value?: string, endOfDay = false) {
    const clean = this.clean(value);
    if (!clean) return null;
    const date = new Date(clean);
    if (Number.isNaN(date.getTime())) return null;
    if (endOfDay) date.setHours(23, 59, 59, 999);
    return date;
  }

  private asDate(value: unknown) {
    if (!value) return null;
    const date = value instanceof Date ? value : new Date(String(value));
    return Number.isNaN(date.getTime()) ? null : date;
  }

  private isSameDay(left: unknown, right: Date) {
    const date = this.asDate(left);
    return (
      !!date &&
      date.getFullYear() === right.getFullYear() &&
      date.getMonth() === right.getMonth() &&
      date.getDate() === right.getDate()
    );
  }

  private isSameMonth(left: unknown, right: Date) {
    const date = this.asDate(left);
    return (
      !!date &&
      date.getFullYear() === right.getFullYear() &&
      date.getMonth() === right.getMonth()
    );
  }

  private isReportType(value: string): value is ReportType {
    return REPORT_TYPES.includes(value as ReportType);
  }

  private formatPdfCell(value: unknown) {
    if (value == null || value === '') return '-';
    if (value instanceof Date) return this.formatDate(value);
    if (typeof value === 'number') return value.toFixed(2);
    return String(value);
  }

  private formatDate(value: Date) {
    return value.toISOString().slice(0, 10);
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

  private clean(value?: string) {
    const text = value?.trim();
    return text ? text : undefined;
  }

  private sum(rows: any[], key: string) {
    return this.round(
      rows.reduce((total, row) => total + this.toNumber(row[key]), 0),
    );
  }

  private toNumber(value: unknown): number {
    if (value == null) return 0;
    if (typeof value === 'number') return value;
    if (
      typeof value === 'object' &&
      'toNumber' in value &&
      typeof value.toNumber === 'function'
    ) {
      return value.toNumber();
    }
    const numberValue = Number(value);
    return Number.isFinite(numberValue) ? numberValue : 0;
  }

  private round(value: number, precision = 2) {
    return Number(value.toFixed(precision));
  }
}
