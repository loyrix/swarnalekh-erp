import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { SecurityService } from './security.service';

const decimal = (value: number) => new Prisma.Decimal(value);

describe('SecurityService', () => {
  const createService = () => {
    const prisma = {
      auditLog: {
        create: jest.fn(),
        findMany: jest.fn(),
        count: jest.fn(),
      },
      tenant: { findUnique: jest.fn() },
      user: { findMany: jest.fn() },
      customer: { findMany: jest.fn() },
      category: { findMany: jest.fn() },
      karigar: { findMany: jest.fn() },
      inventoryItem: { findMany: jest.fn() },
      dailyRate: { findMany: jest.fn() },
      invoice: { findMany: jest.fn() },
      payment: { findMany: jest.fn() },
      mortgageLoan: { findMany: jest.fn() },
      mortgagePayment: { findMany: jest.fn() },
    };

    return {
      service: new SecurityService(prisma as unknown as PrismaService),
      prisma,
    };
  };

  it('returns filtered tenant activity logs', async () => {
    const { service, prisma } = createService();
    const createdAt = new Date('2026-06-10T10:00:00.000Z');

    prisma.auditLog.findMany.mockResolvedValue([
      {
        id: 'log-1',
        action: 'create',
        entityType: 'inventory',
        entityId: '11111111-1111-4111-8111-111111111111',
        oldValues: null,
        newValues: { path: '/inventory' },
        ipAddress: '127.0.0.1',
        createdAt,
        user: {
          id: 'user-1',
          name: 'Asha',
          email: 'asha@example.com',
          phone: '+919999000111',
          role: 'owner',
        },
      },
    ]);
    prisma.auditLog.count.mockResolvedValue(1);

    await expect(
      service.getActivityLogs('tenant-1', {
        entityType: 'inventory',
        search: 'Asha',
        dateFrom: '2026-06-10',
        dateTo: '2026-06-10',
        limit: 25,
      }),
    ).resolves.toEqual({
      generatedAt: expect.any(String),
      filters: {
        entityType: 'inventory',
        action: null,
        search: 'Asha',
        dateFrom: '2026-06-10',
        dateTo: '2026-06-10',
        limit: 25,
      },
      total: 1,
      logs: [
        {
          id: 'log-1',
          action: 'create',
          entityType: 'inventory',
          entityId: '11111111-1111-4111-8111-111111111111',
          oldValues: null,
          newValues: { path: '/inventory' },
          ipAddress: '127.0.0.1',
          createdAt,
          user: {
            id: 'user-1',
            name: 'Asha',
            email: 'asha@example.com',
            phone: '+919999000111',
            role: 'owner',
          },
        },
      ],
    });

    expect(prisma.auditLog.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          tenantId: 'tenant-1',
          entityType: { contains: 'inventory', mode: 'insensitive' },
          OR: expect.any(Array),
          createdAt: expect.objectContaining({
            gte: expect.any(Date),
            lte: expect.any(Date),
          }),
        }),
        take: 25,
      }),
    );
  });

  it('exports a PDF-scoped tenant backup as JSON base64', async () => {
    const { service, prisma } = createService();

    prisma.tenant.findUnique.mockResolvedValue({
      id: 'tenant-1',
      shopName: 'SwarnaLekh',
    });
    prisma.user.findMany.mockResolvedValue([
      {
        id: 'user-1',
        tenantId: 'tenant-1',
        name: 'Asha',
        passwordHash: 'secret-hash',
      },
    ]);
    prisma.customer.findMany.mockResolvedValue([{ id: 'customer-1' }]);
    prisma.category.findMany.mockResolvedValue([{ id: 'category-1' }]);
    prisma.karigar.findMany.mockResolvedValue([]);
    prisma.inventoryItem.findMany.mockResolvedValue([
      { id: 'item-1', sellingPrice: decimal(59000) },
    ]);
    prisma.dailyRate.findMany.mockResolvedValue([{ id: 'rate-1' }]);
    prisma.invoice.findMany.mockResolvedValue([{ id: 'invoice-1', items: [] }]);
    prisma.payment.findMany.mockResolvedValue([]);
    prisma.mortgageLoan.findMany.mockResolvedValue([
      { id: 'loan-1', ornaments: [], payments: [] },
    ]);
    prisma.mortgagePayment.findMany.mockResolvedValue([]);
    prisma.auditLog.findMany.mockResolvedValue([{ id: 'log-1' }]);
    prisma.auditLog.create.mockResolvedValue({ id: 'log-2' });

    const payload = await service.createBackup('tenant-1', 'user-1');
    const backup = JSON.parse(Buffer.from(payload.base64, 'base64').toString());

    expect(payload).toMatchObject({
      fileName: expect.stringMatching(/^swarnalekh-backup-/),
      mimeType: 'application/json',
      counts: {
        users: 1,
        customers: 1,
        categories: 1,
        karigars: 0,
        inventoryItems: 1,
        dailyRates: 1,
        invoices: 1,
        payments: 0,
        mortgageLoans: 1,
        mortgagePayments: 0,
        auditLogs: 1,
      },
    });
    expect(backup.appName).toBe('SwarnaLekh');
    expect(backup.scope).toEqual(
      expect.arrayContaining([
        'inventory',
        'billing',
        'mortgage',
        'activityLogs',
      ]),
    );
    expect(backup.data.users[0].passwordHash).toBeNull();
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          tenantId: 'tenant-1',
          userId: 'user-1',
          action: 'backup_export',
          entityType: 'backup',
        }),
      }),
    );
  });

  it('redacts sensitive fields in activity payloads', async () => {
    const { service, prisma } = createService();
    prisma.auditLog.create.mockResolvedValue({ id: 'log-1' });

    await service.recordActivity({
      tenantId: 'tenant-1',
      userId: 'user-1',
      action: 'create',
      entityType: 'customer',
      newValues: {
        password: 'secret',
        aadhaarNumber: '123456789012',
        panNumber: 'ABCDE1234F',
      },
    });

    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          newValues: {
            password: '[redacted]',
            aadhaarNumber: '********9012',
            panNumber: '******234F',
          },
        }),
      }),
    );
  });
});
