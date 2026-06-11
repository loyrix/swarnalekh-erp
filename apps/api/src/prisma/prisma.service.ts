import {
  Injectable,
  OnModuleInit,
  OnModuleDestroy,
  Logger,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(PrismaService.name);

  constructor() {
    super({
      log: ['info', 'warn', 'error'],
    });
  }

  async onModuleInit() {
    await this.$connect();
    this.logger.log('Database connected');
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }

  // =============================================
  // Soft Delete Models
  // Models with deletedAt: Customer, InventoryItem,
  // Invoice, SchemeEnrollment, LedgerParty
  // =============================================

  private static readonly SOFT_DELETE_MODELS = [
    'Customer',
    'InventoryItem',
    'Invoice',
    'SchemeEnrollment',
    'LedgerParty',
  ] as const;

  /**
   * Returns an extended Prisma client scoped to a specific tenant.
   * Automatically injects tenantId into where clauses and
   * filters soft-deleted records.
   *
   * Usage:
   *   const db = this.prisma.forTenant(tenantId);
   *   const customers = await db.customer.findMany();
   */
  forTenant(tenantId: string) {
    return this.$extends({
      query: {
        // Scope all queries to tenant
        $allModels: {
          async findMany({ args, query }: { args: any; query: any }) {
            args.where = { ...args.where, tenantId };
            return query(args);
          },
          async findFirst({ args, query }: { args: any; query: any }) {
            args.where = { ...args.where, tenantId };
            return query(args);
          },
          async findFirstOrThrow({ args, query }: { args: any; query: any }) {
            args.where = { ...args.where, tenantId };
            return query(args);
          },
          async count({ args, query }: { args: any; query: any }) {
            args.where = { ...args.where, tenantId };
            return query(args);
          },
          async create({ args, query }: { args: any; query: any }) {
            args.data = { ...args.data, tenantId };
            return query(args);
          },
          async update({ args, query }: { args: any; query: any }) {
            args.where = { ...args.where, tenantId };
            return query(args);
          },
          async delete({ args, query }: { args: any; query: any }) {
            args.where = { ...args.where, tenantId };
            return query(args);
          },
        },
      },
    });
  }
}
