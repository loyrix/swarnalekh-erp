import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service.js';
import {
  CsvPayload,
  csvPayload,
  CsvValue,
  toCsv,
} from '../../common/csv.util.js';
import { ExportQueryDto } from './export.dto.js';

export const EXPORT_TYPES = [
  'invoices',
  'inventory',
  'customers',
  'activity',
] as const;

export type ExportType = (typeof EXPORT_TYPES)[number];

@Injectable()
export class ExportService {
  constructor(private readonly prisma: PrismaService) {}

  async export(
    tenantId: string,
    type: string,
    query: ExportQueryDto,
  ): Promise<CsvPayload> {
    switch (type) {
      case 'invoices':
        return this.exportInvoices(tenantId, query);
      case 'inventory':
        return this.exportInventory(tenantId, query);
      case 'customers':
        return this.exportCustomers(tenantId, query);
      case 'activity':
        return this.exportActivity(tenantId, query);
      default:
        throw new BadRequestException(
          `Unknown export type "${type}". Expected one of: ${EXPORT_TYPES.join(', ')}.`,
        );
    }
  }

  private async exportInvoices(tenantId: string, query: ExportQueryDto) {
    const invoiceDate = this.dateRange(query);
    const invoices = await this.prisma.invoice.findMany({
      where: {
        tenantId,
        deletedAt: null,
        ...(invoiceDate ? { invoiceDate } : {}),
        ...(query.search?.trim()
          ? {
              OR: [
                {
                  invoiceNumber: {
                    contains: query.search.trim(),
                    mode: 'insensitive',
                  },
                },
                {
                  customerName: {
                    contains: query.search.trim(),
                    mode: 'insensitive',
                  },
                },
              ],
            }
          : {}),
      },
      include: { _count: { select: { items: true } } },
      orderBy: { createdAt: 'desc' },
      take: 10000,
    });

    const headers = [
      'Invoice No',
      'Date',
      'Customer',
      'Phone',
      'Items',
      'Subtotal',
      'Discount',
      'GST',
      'Grand Total',
      'Paid',
      'Balance',
      'Payment Mode',
    ];
    const rows: CsvValue[][] = invoices.map((inv) => [
      inv.invoiceNumber,
      this.date(inv.invoiceDate),
      inv.customerName ?? '',
      inv.customerPhone ?? '',
      inv._count.items,
      this.num(inv.subtotal),
      this.num(inv.discountAmount),
      this.num(inv.totalTax),
      this.num(inv.grandTotal),
      this.num(inv.amountPaid),
      this.num(inv.balanceDue),
      inv.paymentMode ?? '',
    ]);

    return csvPayload(
      this.fileName('invoices'),
      toCsv(headers, rows),
      rows.length,
    );
  }

  private async exportInventory(tenantId: string, query: ExportQueryDto) {
    const items = await this.prisma.inventoryItem.findMany({
      where: {
        tenantId,
        deletedAt: null,
        ...(query.status?.trim() ? { status: query.status.trim() } : {}),
        ...(query.search?.trim()
          ? {
              OR: [
                {
                  itemName: {
                    contains: query.search.trim(),
                    mode: 'insensitive',
                  },
                },
                {
                  tagNumber: {
                    contains: query.search.trim(),
                    mode: 'insensitive',
                  },
                },
              ],
            }
          : {}),
      },
      include: { category: { select: { name: true } } },
      orderBy: { createdAt: 'desc' },
      take: 10000,
    });

    const headers = [
      'Tag',
      'Item',
      'Category',
      'Metal',
      'Karat',
      'Gross Wt (g)',
      'Net Wt (g)',
      'Qty',
      'Status',
      'Selling Price',
    ];
    const rows: CsvValue[][] = items.map((item) => [
      item.tagNumber ?? '',
      item.itemName ?? '',
      item.category?.name ?? '',
      item.metalType,
      item.karat ?? '',
      this.num(item.grossWeight),
      this.num(item.netWeight),
      item.quantity,
      item.status,
      this.num(item.sellingPrice),
    ]);

    return csvPayload(
      this.fileName('inventory'),
      toCsv(headers, rows),
      rows.length,
    );
  }

  private async exportCustomers(tenantId: string, query: ExportQueryDto) {
    const customers = await this.prisma.customer.findMany({
      where: {
        tenantId,
        deletedAt: null,
        ...(query.search?.trim()
          ? {
              OR: [
                {
                  name: { contains: query.search.trim(), mode: 'insensitive' },
                },
                { phone: { contains: query.search.trim() } },
              ],
            }
          : {}),
      },
      orderBy: { name: 'asc' },
      take: 10000,
    });

    const headers = [
      'Name',
      'Phone',
      'Email',
      'City',
      'Total Purchases',
      'Visits',
      'Last Visit',
    ];
    const rows: CsvValue[][] = customers.map((c) => [
      c.name,
      c.phone ?? '',
      c.email ?? '',
      c.city ?? '',
      this.num(c.totalPurchases),
      c.totalVisits,
      this.date(c.lastVisitAt),
    ]);

    return csvPayload(
      this.fileName('customers'),
      toCsv(headers, rows),
      rows.length,
    );
  }

  private async exportActivity(tenantId: string, query: ExportQueryDto) {
    const createdAt = this.dateRange(query);
    const logs = await this.prisma.auditLog.findMany({
      where: { tenantId, ...(createdAt ? { createdAt } : {}) },
      include: { user: { select: { name: true, role: true } } },
      orderBy: { createdAt: 'desc' },
      take: 10000,
    });

    const headers = [
      'Date',
      'User',
      'Role',
      'Action',
      'Entity',
      'Entity ID',
      'IP Address',
    ];
    const rows: CsvValue[][] = logs.map((log) => [
      this.dateTime(log.createdAt),
      log.user?.name ?? 'System',
      log.user?.role ?? '',
      log.action,
      log.entityType ?? '',
      log.entityId ?? '',
      log.ipAddress ?? '',
    ]);

    return csvPayload(
      this.fileName('activity'),
      toCsv(headers, rows),
      rows.length,
    );
  }

  private dateRange(query: ExportQueryDto): Prisma.DateTimeFilter | null {
    const from = this.parseDate(query.dateFrom, false);
    const to = this.parseDate(query.dateTo, true);
    if (!from && !to) return null;
    return { ...(from ? { gte: from } : {}), ...(to ? { lte: to } : {}) };
  }

  private parseDate(value: string | undefined, endOfDay: boolean) {
    if (!value?.trim()) return null;
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return null;
    if (endOfDay) date.setUTCHours(23, 59, 59, 999);
    return date;
  }

  private num(value: unknown): number {
    if (value == null) return 0;
    if (typeof value === 'number') return value;
    if (
      typeof value === 'object' &&
      'toNumber' in value &&
      typeof (value as { toNumber: () => number }).toNumber === 'function'
    ) {
      return (value as { toNumber: () => number }).toNumber();
    }
    return Number(value) || 0;
  }

  private date(value: Date | null): string {
    return value ? value.toISOString().slice(0, 10) : '';
  }

  private dateTime(value: Date): string {
    return value.toISOString().slice(0, 16).replace('T', ' ');
  }

  private fileName(type: string): string {
    return `${type}-${new Date().toISOString().slice(0, 10)}`;
  }
}
