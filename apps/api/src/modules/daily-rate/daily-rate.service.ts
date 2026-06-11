import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { BulkUpdateDailyRateDto } from './daily-rate.dto.js';

@Injectable()
export class DailyRateService {
  constructor(private readonly prisma: PrismaService) {}

  async getLatestRates(tenantId: string) {
    const db = this.prisma.forTenant(tenantId);

    // Find the max date that has rates
    const latestRate = await db.dailyRate.findFirst({
      orderBy: { rateDate: 'desc' },
      select: { rateDate: true },
    });

    if (!latestRate) {
      return [];
    }

    // Get all rates for that latest date
    return db.dailyRate.findMany({
      where: {
        rateDate: latestRate.rateDate,
      },
      orderBy: [
        { metalType: 'asc' },
        { karat: 'desc' },
      ],
    });
  }

  async getRatesByDate(tenantId: string, queryDate: Date) {
    if (Number.isNaN(queryDate.getTime())) {
      throw new BadRequestException('Invalid rate date');
    }

    const db = this.prisma.forTenant(tenantId);
    
    // Ensure we capture the entire day
    const startOfDay = new Date(queryDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(queryDate);
    endOfDay.setHours(23, 59, 59, 999);

    return db.dailyRate.findMany({
      where: {
        rateDate: {
          gte: startOfDay,
          lte: endOfDay,
        },
      },
      orderBy: [
        { metalType: 'asc' },
        { karat: 'desc' },
      ],
    });
  }

  async getTodayRates(tenantId: string) {
    return this.getRatesByDate(tenantId, new Date());
  }

  async getHistory(tenantId: string, days = 15) {
    const safeDays = Number.isFinite(days) ? Math.max(1, Math.min(days, 90)) : 15;
    const startDate = new Date();
    startDate.setHours(0, 0, 0, 0);
    startDate.setDate(startDate.getDate() - (safeDays - 1));

    const rates = await this.prisma.dailyRate.findMany({
      where: {
        tenantId,
        rateDate: {
          gte: startDate,
        },
      },
      orderBy: [{ rateDate: 'desc' }, { metalType: 'asc' }, { karat: 'desc' }],
    });

    const grouped = new Map<string, typeof rates>();
    for (const rate of rates) {
      const key = rate.rateDate.toISOString().split('T')[0];
      grouped.set(key, [...(grouped.get(key) ?? []), rate]);
    }

    return Array.from(grouped.entries()).map(([date, entries]) => ({
      date,
      rates: entries,
    }));
  }

  async bulkUpdate(tenantId: string, userId: string, dto: BulkUpdateDailyRateDto) {
    if (dto.rates.length === 0) {
      throw new BadRequestException('At least one rate is required');
    }

    return this.prisma.$transaction(async (tx) => {
      const results = [];

      for (const req of dto.rates) {
        if (Number.isNaN(req.rateDate.getTime())) {
          throw new BadRequestException('Invalid rate date');
        }

        const rateDateStart = new Date(req.rateDate);
        rateDateStart.setHours(0, 0, 0, 0);
        const normalizedKarat = req.karat?.trim() || null;

        const existing = await tx.dailyRate.findFirst({
          where: {
            tenantId,
            rateDate: rateDateStart,
            metalType: req.metalType,
            karat: normalizedKarat,
          },
        });

        const upserted = existing
          ? await tx.dailyRate.update({
              where: { id: existing.id },
              data: {
                ratePerGram: req.ratePerGram,
                source: req.source || 'manual',
                setBy: userId,
              },
            })
          : await tx.dailyRate.create({
              data: {
                tenantId,
                rateDate: rateDateStart,
                metalType: req.metalType,
                karat: normalizedKarat,
                ratePerGram: req.ratePerGram,
                source: req.source || 'manual',
                setBy: userId,
              },
            });

        results.push(upserted);
      }

      return results;
    });
  }
}
