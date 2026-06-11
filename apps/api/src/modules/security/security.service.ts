import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service.js';
import { ActivityLogQueryDto } from './security.dto.js';

const BACKUP_ENTITY_LIMIT = 5000;
const BACKUP_AUDIT_LIMIT = 1000;

type AuditInput = {
  tenantId: string;
  userId?: string | null;
  action: string;
  entityType?: string | null;
  entityId?: string | null;
  oldValues?: unknown;
  newValues?: unknown;
  ipAddress?: string | null;
};

@Injectable()
export class SecurityService {
  constructor(private readonly prisma: PrismaService) {}

  async recordActivity(input: AuditInput) {
    return this.prisma.auditLog.create({
      data: {
        tenantId: input.tenantId,
        userId: input.userId ?? null,
        action: input.action,
        entityType: input.entityType ?? null,
        entityId: this.isUuid(input.entityId) ? input.entityId : null,
        oldValues: this.toJson(input.oldValues),
        newValues: this.toJson(input.newValues),
        ipAddress: input.ipAddress ?? null,
      },
    });
  }

  async getActivityLogs(tenantId: string, query: ActivityLogQueryDto) {
    const where = this.buildActivityWhere(tenantId, query);
    const take = Math.min(Math.max(query.limit ?? 50, 1), 100);

    const [logs, total] = await Promise.all([
      this.prisma.auditLog.findMany({
        where,
        include: {
          user: {
            select: {
              id: true,
              name: true,
              email: true,
              phone: true,
              role: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        take,
      }),
      this.prisma.auditLog.count({ where }),
    ]);

    return {
      generatedAt: new Date().toISOString(),
      filters: {
        entityType: query.entityType?.trim() || null,
        action: query.action?.trim() || null,
        search: query.search?.trim() || null,
        dateFrom: query.dateFrom?.trim() || null,
        dateTo: query.dateTo?.trim() || null,
        limit: take,
      },
      total,
      logs: logs.map((log) => ({
        id: log.id,
        action: log.action,
        entityType: log.entityType,
        entityId: log.entityId,
        oldValues: log.oldValues,
        newValues: log.newValues,
        ipAddress: log.ipAddress,
        createdAt: log.createdAt,
        user: log.user
          ? {
              id: log.user.id,
              name: log.user.name,
              email: log.user.email,
              phone: log.user.phone,
              role: log.user.role,
            }
          : null,
      })),
    };
  }

  async createBackup(tenantId: string, userId?: string | null) {
    const generatedAt = new Date().toISOString();
    const [
      tenant,
      users,
      customers,
      categories,
      karigars,
      inventoryItems,
      dailyRates,
      invoices,
      payments,
      mortgageLoans,
      mortgagePayments,
      auditLogs,
    ] = await Promise.all([
      this.prisma.tenant.findUnique({
        where: { id: tenantId },
      }),
      this.prisma.user.findMany({
        where: { tenantId },
        orderBy: { createdAt: 'asc' },
        take: BACKUP_ENTITY_LIMIT,
      }),
      this.prisma.customer.findMany({
        where: { tenantId },
        orderBy: { createdAt: 'asc' },
        take: BACKUP_ENTITY_LIMIT,
      }),
      this.prisma.category.findMany({
        where: { tenantId },
        orderBy: { createdAt: 'asc' },
        take: BACKUP_ENTITY_LIMIT,
      }),
      this.prisma.karigar.findMany({
        where: { tenantId },
        orderBy: { createdAt: 'asc' },
        take: BACKUP_ENTITY_LIMIT,
      }),
      this.prisma.inventoryItem.findMany({
        where: { tenantId },
        include: { category: true, karigar: true },
        orderBy: { createdAt: 'asc' },
        take: BACKUP_ENTITY_LIMIT,
      }),
      this.prisma.dailyRate.findMany({
        where: { tenantId },
        orderBy: [{ rateDate: 'asc' }, { metalType: 'asc' }, { karat: 'asc' }],
        take: BACKUP_ENTITY_LIMIT,
      }),
      this.prisma.invoice.findMany({
        where: { tenantId },
        include: { items: true, payments: true },
        orderBy: { createdAt: 'asc' },
        take: BACKUP_ENTITY_LIMIT,
      }),
      this.prisma.payment.findMany({
        where: { tenantId },
        orderBy: { createdAt: 'asc' },
        take: BACKUP_ENTITY_LIMIT,
      }),
      this.prisma.mortgageLoan.findMany({
        where: { tenantId },
        include: { ornaments: true, payments: true },
        orderBy: { createdAt: 'asc' },
        take: BACKUP_ENTITY_LIMIT,
      }),
      this.prisma.mortgagePayment.findMany({
        where: { tenantId },
        orderBy: { createdAt: 'asc' },
        take: BACKUP_ENTITY_LIMIT,
      }),
      this.prisma.auditLog.findMany({
        where: { tenantId },
        include: {
          user: {
            select: {
              id: true,
              name: true,
              email: true,
              phone: true,
              role: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: BACKUP_AUDIT_LIMIT,
      }),
    ]);

    const backup = {
      appName: 'SwarnaLekh',
      generatedAt,
      tenantId,
      scope: [
        'tenant',
        'users',
        'customers',
        'categories',
        'karigars',
        'inventory',
        'dailyRates',
        'billing',
        'mortgage',
        'activityLogs',
      ],
      data: {
        tenant,
        users: users.map((user) => ({ ...user, passwordHash: null })),
        customers,
        categories,
        karigars,
        inventoryItems,
        dailyRates,
        invoices,
        payments,
        mortgageLoans,
        mortgagePayments,
        auditLogs,
      },
    };

    const json = JSON.stringify(backup, null, 2);
    const fileName = `swarnalekh-backup-${generatedAt.slice(0, 10)}.json`;

    await this.recordActivity({
      tenantId,
      userId,
      action: 'backup_export',
      entityType: 'backup',
      newValues: {
        fileName,
        counts: this.backupCounts(backup.data),
      },
    });

    return {
      generatedAt,
      fileName,
      mimeType: 'application/json',
      counts: this.backupCounts(backup.data),
      base64: Buffer.from(json, 'utf8').toString('base64'),
    };
  }

  sanitizeValue(value: unknown): unknown {
    return this.sanitize(value);
  }

  private buildActivityWhere(
    tenantId: string,
    query: ActivityLogQueryDto,
  ): Prisma.AuditLogWhereInput {
    const search = query.search?.trim();
    const createdAt: Prisma.DateTimeFilter = {};
    const dateFrom = this.parseDate(query.dateFrom, false);
    const dateTo = this.parseDate(query.dateTo, true);

    if (dateFrom) createdAt.gte = dateFrom;
    if (dateTo) createdAt.lte = dateTo;

    return {
      tenantId,
      ...(query.entityType?.trim()
        ? {
            entityType: {
              contains: query.entityType.trim(),
              mode: 'insensitive',
            },
          }
        : {}),
      ...(query.action?.trim()
        ? { action: { contains: query.action.trim(), mode: 'insensitive' } }
        : {}),
      ...(Object.keys(createdAt).length ? { createdAt } : {}),
      ...(search
        ? {
            OR: [
              { action: { contains: search, mode: 'insensitive' } },
              { entityType: { contains: search, mode: 'insensitive' } },
              { user: { name: { contains: search, mode: 'insensitive' } } },
              { user: { email: { contains: search, mode: 'insensitive' } } },
            ],
          }
        : {}),
    };
  }

  private backupCounts(data: {
    users: unknown[];
    customers: unknown[];
    categories: unknown[];
    karigars: unknown[];
    inventoryItems: unknown[];
    dailyRates: unknown[];
    invoices: unknown[];
    payments: unknown[];
    mortgageLoans: unknown[];
    mortgagePayments: unknown[];
    auditLogs: unknown[];
  }) {
    return {
      users: data.users.length,
      customers: data.customers.length,
      categories: data.categories.length,
      karigars: data.karigars.length,
      inventoryItems: data.inventoryItems.length,
      dailyRates: data.dailyRates.length,
      invoices: data.invoices.length,
      payments: data.payments.length,
      mortgageLoans: data.mortgageLoans.length,
      mortgagePayments: data.mortgagePayments.length,
      auditLogs: data.auditLogs.length,
    };
  }

  private parseDate(value: string | undefined, endOfDay: boolean) {
    if (!value?.trim()) return null;
    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) return null;
    if (endOfDay) {
      parsed.setHours(23, 59, 59, 999);
    } else {
      parsed.setHours(0, 0, 0, 0);
    }
    return parsed;
  }

  private toJson(value: unknown): Prisma.InputJsonValue | undefined {
    if (value === undefined) return undefined;
    return this.sanitize(value) as Prisma.InputJsonValue;
  }

  private sanitize(value: unknown): unknown {
    if (Array.isArray(value)) {
      return value.slice(0, 25).map((entry) => this.sanitize(entry));
    }

    if (value && typeof value === 'object') {
      const entries = Object.entries(value as Record<string, unknown>).slice(
        0,
        50,
      );
      return Object.fromEntries(
        entries.map(([key, entry]) => [key, this.sanitizeEntry(key, entry)]),
      );
    }

    if (typeof value === 'string') {
      return value.length > 250 ? `${value.slice(0, 247)}...` : value;
    }

    return value;
  }

  private sanitizeEntry(key: string, value: unknown) {
    const normalizedKey = key.toLowerCase();
    if (
      normalizedKey.includes('password') ||
      normalizedKey.includes('token') ||
      normalizedKey.includes('secret') ||
      normalizedKey.includes('authorization') ||
      normalizedKey.includes('base64')
    ) {
      return '[redacted]';
    }

    if (
      normalizedKey.includes('aadhaar') ||
      normalizedKey.includes('aadhar') ||
      normalizedKey === 'pan' ||
      normalizedKey.includes('pannumber') ||
      normalizedKey.includes('pan_number')
    ) {
      return this.maskIdentifier(value);
    }

    return this.sanitize(value);
  }

  private maskIdentifier(value: unknown) {
    if (typeof value !== 'string') return value;
    if (value.length <= 4) return '****';
    return `${'*'.repeat(Math.max(value.length - 4, 4))}${value.slice(-4)}`;
  }

  private isUuid(value: unknown): value is string {
    return (
      typeof value === 'string' &&
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
        value,
      )
    );
  }
}
