import { Injectable } from '@nestjs/common';
import { calculateMortgagePayable } from '@swarnbook/business-logic';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class DashboardService {
  constructor(private readonly prisma: PrismaService) {}

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

  async getStats(tenantId: string) {
    const now = new Date();
    const today = new Date(now);
    today.setHours(0, 0, 0, 0);
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    const latestRateDate = await this.prisma.dailyRate.findFirst({
      where: { tenantId },
      orderBy: { rateDate: 'desc' },
      select: { rateDate: true },
    });

    const [
      inventoryItems,
      latestRates,
      todaysInvoices,
      monthlyInvoices,
      totalBillsGenerated,
      activeMortgageLoans,
      monthlySoldItemsObj,
    ] = await Promise.all([
      this.prisma.inventoryItem.findMany({
        where: { tenantId, deletedAt: null },
        select: {
          metalType: true,
          karat: true,
          quantity: true,
          grossWeight: true,
          netWeight: true,
          purchaseRate: true,
          stoneValue: true,
          status: true,
        },
      }),
      latestRateDate
        ? this.prisma.dailyRate.findMany({
            where: {
              tenantId,
              rateDate: latestRateDate.rateDate,
            },
            select: {
              metalType: true,
              karat: true,
              ratePerGram: true,
            },
          })
        : Promise.resolve([]),
      this.prisma.invoice.findMany({
        where: {
          tenantId,
          invoiceDate: { gte: today },
          deletedAt: null,
        },
        select: { grandTotal: true },
      }),
      this.prisma.invoice.findMany({
        where: {
          tenantId,
          invoiceDate: { gte: monthStart },
          deletedAt: null,
        },
        select: { grandTotal: true },
      }),
      this.prisma.invoice.count({
        where: {
          tenantId,
          deletedAt: null,
        },
      }),
      this.prisma.mortgageLoan.findMany({
        where: { tenantId, status: 'active', deletedAt: null },
      }),
      this.prisma.invoiceItem.aggregate({
        where: {
          invoice: {
            tenantId,
            invoiceDate: { gte: monthStart },
            deletedAt: null,
          },
        },
        _sum: { quantity: true },
      }),
    ]);

    const rateMap = new Map<string, number>();
    for (const rate of latestRates) {
      rateMap.set(
        `${rate.metalType}:${rate.karat ?? ''}`.toLowerCase(),
        this.toNumber(rate.ratePerGram),
      );
    }

    const availableInventory = inventoryItems.filter(
      (item) => item.status !== 'sold',
    );
    const totalGoldStock = availableInventory.reduce((sum, item) => {
      if (item.metalType.toLowerCase() !== 'gold') return sum;
      return sum + this.toNumber(item.netWeight) * item.quantity;
    }, 0);
    const totalSilverStock = availableInventory.reduce((sum, item) => {
      if (item.metalType.toLowerCase() !== 'silver') return sum;
      return sum + this.toNumber(item.netWeight) * item.quantity;
    }, 0);
    const totalInventoryValue = availableInventory.reduce((sum, item) => {
      const exactKey = `${item.metalType}:${item.karat ?? ''}`.toLowerCase();
      const fallbackKey = `${item.metalType}:`.toLowerCase();
      const rate =
        rateMap.get(exactKey) ??
        rateMap.get(fallbackKey) ??
        this.toNumber(item.purchaseRate);
      const metalValue =
        rate > 0 ? this.toNumber(item.netWeight) * item.quantity * rate : 0;
      const stoneValue = this.toNumber(item.stoneValue) * item.quantity;

      return sum + metalValue + stoneValue;
    }, 0);

    const todaysSales = todaysInvoices.reduce(
      (sum, invoice) => sum + this.toNumber(invoice.grandTotal),
      0,
    );
    const monthlyRevenue = monthlyInvoices.reduce(
      (sum, invoice) => sum + this.toNumber(invoice.grandTotal),
      0,
    );
    const mortgageSnapshots = activeMortgageLoans.map((loan) =>
      calculateMortgagePayable({
        principalAmount: this.toNumber(loan.principalAmount),
        interestRateMonthly: this.toNumber(loan.interestRateMonthly),
        loanDate: loan.loanDate,
        interestPaid: this.toNumber(loan.totalInterestPaid),
        principalPaid: this.toNumber(loan.totalPrincipalPaid),
      }),
    );
    const pendingMortgageInterest = mortgageSnapshots.reduce(
      (sum, snapshot) => sum + snapshot.pendingInterestAmount,
      0,
    );
    const activeMortgagePrincipal = mortgageSnapshots.reduce(
      (sum, snapshot) => sum + snapshot.outstandingPrincipal,
      0,
    );

    const soldProductsThisMonth = monthlySoldItemsObj._sum.quantity ?? 0;

    return {
      totalGoldStock: this.round(totalGoldStock, 3),
      totalSilverStock: this.round(totalSilverStock, 3),
      totalInventoryValue: this.round(totalInventoryValue),
      monthlyRevenue: this.round(monthlyRevenue),
      pendingMortgageInterest: this.round(pendingMortgageInterest),
      activeLoans: activeMortgageLoans.length,
      todaysSales: this.round(todaysSales),
      totalBillsGenerated,
      activeMortgagePrincipal: this.round(activeMortgagePrincipal),
      soldProductsThisMonth,
    };
  }

  async getBootstrap(
    tenantId: string,
    appUser?: { name?: string | null; role?: string | null },
  ) {
    const [stats, tenant] = await Promise.all([
      this.getStats(tenantId),
      this.prisma.tenant.findUnique({
        where: { id: tenantId },
        select: { shopName: true },
      }),
    ]);

    return {
      stats,
      user: {
        name: appUser?.name ?? 'Owner',
        role: appUser?.role ?? 'staff',
      },
      tenant: {
        shopName: tenant?.shopName ?? '',
      },
    };
  }
}
