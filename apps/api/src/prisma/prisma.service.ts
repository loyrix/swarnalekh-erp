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

  private static readonly SOFT_DELETE_MODELS = new Set([
    'Customer',
    'InventoryItem',
    'Invoice',
    'SchemeEnrollment',
    'LedgerParty',
  ]);

  /**
   * Builds the where clause for a tenant-scoped READ. Always injects the
   * tenantId, and — for soft-delete models — also excludes soft-deleted rows
   * unless the caller explicitly set `deletedAt` (so intentional queries for
   * deleted records still work). Pure/static so it can be unit-tested.
   */
  static scopeReadWhere(
    model: string | undefined,
    where: Record<string, any> | undefined,
    tenantId: string,
  ): Record<string, any> {
    const scoped: Record<string, any> = { ...(where ?? {}), tenantId };
    if (
      model !== undefined &&
      PrismaService.SOFT_DELETE_MODELS.has(model) &&
      scoped.deletedAt === undefined
    ) {
      scoped.deletedAt = null;
    }
    return scoped;
  }

  /**
   * Returns an extended Prisma client scoped to a specific tenant.
   * Automatically injects tenantId into where clauses and, for soft-delete
   * models, filters out soft-deleted records on reads.
   *
   * Usage:
   *   const db = this.prisma.forTenant(tenantId);
   *   const customers = await db.customer.findMany();
   */
  forTenant(tenantId: string) {
    const scopeRead = (model: string | undefined, where: any) =>
      PrismaService.scopeReadWhere(model, where, tenantId);
    return this.$extends({
      query: {
        // Scope all queries to tenant
        $allModels: {
          async findMany({ model, args, query }: any) {
            args.where = scopeRead(model, args.where);
            return query(args);
          },
          async findFirst({ model, args, query }: any) {
            args.where = scopeRead(model, args.where);
            return query(args);
          },
          async findFirstOrThrow({ model, args, query }: any) {
            args.where = scopeRead(model, args.where);
            return query(args);
          },
          async count({ model, args, query }: any) {
            args.where = scopeRead(model, args.where);
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
