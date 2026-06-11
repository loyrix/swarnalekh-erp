import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { DashboardService } from './dashboard.service';

const decimal = (value: number) => new Prisma.Decimal(value);

const makeActiveLoan = (overrides: Record<string, unknown> = {}) => ({
  principalAmount: decimal(100000),
  interestRateMonthly: decimal(2),
  loanDate: new Date(),
  totalInterestPaid: decimal(0),
  totalPrincipalPaid: decimal(0),
  ...overrides,
});

describe('DashboardService', () => {
  const createService = () => {
    const prisma = {
      dailyRate: {
        findFirst: jest.fn(),
        findMany: jest.fn(),
      },
      inventoryItem: {
        findMany: jest.fn(),
      },
      invoice: {
        findMany: jest.fn(),
        count: jest.fn(),
      },
      mortgageLoan: {
        findMany: jest.fn(),
      },
      tenant: {
        findUnique: jest.fn(),
      },
    };

    return {
      service: new DashboardService(prisma as unknown as PrismaService),
      prisma,
    };
  };

  it('aggregates the PDF dashboard metrics for the tenant', async () => {
    const { service, prisma } = createService();
    const rateDate = new Date('2026-06-10T00:00:00.000Z');

    prisma.dailyRate.findFirst.mockResolvedValue({ rateDate });
    prisma.dailyRate.findMany.mockResolvedValue([
      { metalType: 'gold', karat: '22K', ratePerGram: decimal(6000) },
      { metalType: 'silver', karat: null, ratePerGram: decimal(75) },
    ]);
    prisma.inventoryItem.findMany.mockResolvedValue([
      {
        metalType: 'gold',
        karat: '22K',
        quantity: 2,
        grossWeight: decimal(22),
        netWeight: decimal(10.5),
        purchaseRate: null,
        stoneValue: decimal(500),
        status: 'in_stock',
      },
      {
        metalType: 'silver',
        karat: null,
        quantity: 3,
        grossWeight: decimal(160),
        netWeight: decimal(50),
        purchaseRate: null,
        stoneValue: decimal(0),
        status: 'in_stock',
      },
      {
        metalType: 'gold',
        karat: '22K',
        quantity: 1,
        grossWeight: decimal(8.4),
        netWeight: decimal(8),
        purchaseRate: null,
        stoneValue: decimal(0),
        status: 'sold',
      },
      {
        metalType: 'platinum',
        karat: null,
        quantity: 1,
        grossWeight: decimal(1),
        netWeight: decimal(1),
        purchaseRate: decimal(1000),
        stoneValue: decimal(0),
        status: 'in_stock',
      },
    ]);
    prisma.invoice.findMany
      .mockResolvedValueOnce([
        { grandTotal: decimal(10000) },
        { grandTotal: decimal(5000) },
      ])
      .mockResolvedValueOnce([
        { grandTotal: decimal(10000) },
        { grandTotal: decimal(5000) },
        { grandTotal: decimal(25000) },
      ]);
    prisma.invoice.count.mockResolvedValue(12);
    prisma.mortgageLoan.findMany.mockResolvedValue([makeActiveLoan()]);

    await expect(service.getStats('tenant-1')).resolves.toEqual({
      totalGoldStock: 21,
      totalSilverStock: 150,
      totalInventoryValue: 139250,
      monthlyRevenue: 40000,
      pendingMortgageInterest: 0,
      activeLoans: 1,
      todaysSales: 15000,
      totalBillsGenerated: 12,
      activeMortgagePrincipal: 100000,
    });
    expect(prisma.inventoryItem.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { tenantId: 'tenant-1', deletedAt: null },
      }),
    );
    expect(prisma.invoice.count).toHaveBeenCalledWith({
      where: { tenantId: 'tenant-1', deletedAt: null },
    });
  });

  it('returns a compact bootstrap payload for the PDF dashboard', async () => {
    const { service, prisma } = createService();
    const stats = {
      totalGoldStock: 0,
      totalSilverStock: 0,
      totalInventoryValue: 0,
      monthlyRevenue: 0,
      pendingMortgageInterest: 0,
      activeLoans: 0,
      todaysSales: 0,
      totalBillsGenerated: 0,
      activeMortgagePrincipal: 0,
    };

    jest.spyOn(service, 'getStats').mockResolvedValue(stats);
    prisma.tenant.findUnique.mockResolvedValue({ shopName: 'SwarnaLekh' });

    await expect(
      service.getBootstrap('tenant-1', { name: 'Asha', role: 'owner' }),
    ).resolves.toEqual({
      stats,
      user: { name: 'Asha', role: 'owner' },
      tenant: { shopName: 'SwarnaLekh' },
    });
  });
});
