import { PrismaService } from './prisma.service';

describe('PrismaService.scopeReadWhere', () => {
  const tenantId = 'tenant-1';

  it('injects the tenantId into an empty where', () => {
    expect(
      PrismaService.scopeReadWhere('Customer', undefined, tenantId),
    ).toEqual({ tenantId, deletedAt: null });
  });

  it('excludes soft-deleted rows for soft-delete models', () => {
    for (const model of ['Customer', 'InventoryItem', 'Invoice']) {
      const where = PrismaService.scopeReadWhere(
        model,
        { status: 'x' },
        tenantId,
      );
      expect(where).toEqual({ status: 'x', tenantId, deletedAt: null });
    }
  });

  it('does not add deletedAt for models without soft delete', () => {
    const where = PrismaService.scopeReadWhere('DailyRate', {}, tenantId);
    expect(where).toEqual({ tenantId });
    expect('deletedAt' in where).toBe(false);
  });

  it('respects an explicit deletedAt so deleted rows can be queried', () => {
    const notNull = { not: null };
    const where = PrismaService.scopeReadWhere(
      'Customer',
      { deletedAt: notNull },
      tenantId,
    );
    expect(where.deletedAt).toBe(notNull);
    expect(where.tenantId).toBe(tenantId);
  });

  it('preserves caller where fields and overrides tenant scope', () => {
    const where = PrismaService.scopeReadWhere(
      'InventoryItem',
      { tenantId: 'attacker', name: 'ring' },
      tenantId,
    );
    expect(where.tenantId).toBe(tenantId);
    expect(where.name).toBe('ring');
    expect(where.deletedAt).toBeNull();
  });

  it('skips soft-delete injection when model is unknown', () => {
    const where = PrismaService.scopeReadWhere(undefined, {}, tenantId);
    expect(where).toEqual({ tenantId });
  });
});
