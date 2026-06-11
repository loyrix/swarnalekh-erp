import { Injectable } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service';

@Injectable()
export class AppService {
  constructor(private readonly prisma: PrismaService) {}

  async getHealth() {
    // Test DB connection
    let dbStatus = 'disconnected';
    let tenantCount = 0;
    let tableCount = 0;

    try {
      // Quick query to verify connection
      const result = await this.prisma.$queryRaw<
        { count: bigint }[]
      >`SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public'`;
      tableCount = Number(result[0].count);
      tenantCount = await this.prisma.tenant.count();
      dbStatus = 'connected';
    } catch {
      dbStatus = 'error';
    }

    return {
      status: 'ok',
      app: 'SwarnaLekh API',
      version: '0.1.0',
      environment: process.env.NODE_ENV || 'development',
      database: {
        status: dbStatus,
        tables: tableCount,
        tenants: tenantCount,
      },
      timestamp: new Date().toISOString(),
    };
  }
}
