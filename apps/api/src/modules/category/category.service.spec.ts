import { ConflictException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CategoryService, DEFAULT_CATEGORIES } from './category.service';

describe('CategoryService', () => {
  const tenantId = 'tenant-1';

  const createService = () => {
    const prisma = {
      category: {
        findMany: jest.fn().mockResolvedValue([]),
        findFirst: jest.fn().mockResolvedValue(null),
        create: jest
          .fn()
          .mockImplementation(({ data }) =>
            Promise.resolve({ id: `cat-${data.name}`, ...data }),
          ),
        update: jest
          .fn()
          .mockImplementation(({ where, data }) =>
            Promise.resolve({ id: where.id, ...data }),
          ),
        delete: jest.fn().mockResolvedValue({}),
      },
      inventoryItem: {
        groupBy: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(0),
      },
    };
    const service = new CategoryService(prisma as unknown as PrismaService);
    return { service, prisma };
  };

  it('seeds the default master list for a shop with no categories', async () => {
    const { service, prisma } = createService();
    // ensureSeeded reads existing (none), then list re-reads (still empty mock).
    await service.list(tenantId);

    expect(prisma.category.create).toHaveBeenCalledTimes(
      DEFAULT_CATEGORIES.length,
    );
    const created = prisma.category.create.mock.calls.map(
      ([args]) => args.data,
    );
    expect(created).toContainEqual({
      tenantId,
      name: 'Ring',
      prefix: 'RG',
    });
    const prefixes = created.map((c: { prefix: string }) => c.prefix);
    expect(new Set(prefixes).size).toBe(prefixes.length); // all unique
  });

  it('upgrades a legacy free-text category instead of duplicating it', async () => {
    const { service, prisma } = createService();
    const legacy = [{ id: 'cat-legacy', name: 'ring', prefix: null }];
    // First findMany = ensureSeeded existing scan; second = leftover scan;
    // third = final list read.
    prisma.category.findMany
      .mockResolvedValueOnce(legacy)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce(legacy);

    await service.list(tenantId);

    // "ring" matched seed "Ring" → gets RG backfilled, not a new row.
    expect(prisma.category.update).toHaveBeenCalledWith({
      where: { id: 'cat-legacy' },
      data: { prefix: 'RG' },
    });
    const createdNames = prisma.category.create.mock.calls.map(
      ([args]) => args.data.name,
    );
    expect(createdNames).not.toContain('Ring');
    expect(createdNames).toContain('Chain');
  });

  it('derives a fallback prefix for unmatched legacy categories', async () => {
    const { service, prisma } = createService();
    const legacy = [{ id: 'cat-x', name: 'Rani Haar Special', prefix: null }];
    prisma.category.findMany
      .mockResolvedValueOnce(legacy)
      .mockResolvedValueOnce(legacy)
      .mockResolvedValueOnce(legacy);

    await service.list(tenantId);

    const backfill = prisma.category.update.mock.calls.find(
      ([args]) => args.where.id === 'cat-x',
    );
    expect(backfill).toBeDefined();
    expect(backfill![0].data.prefix).toMatch(/^[A-Z]{2,3}$/);
  });

  it('rejects creating a category whose prefix is taken', async () => {
    const { service, prisma } = createService();
    prisma.category.findFirst
      .mockResolvedValueOnce(null) // name duplicate check
      .mockResolvedValueOnce({ id: 'other', name: 'Ring' }); // prefix clash

    await expect(
      service.create(tenantId, { name: 'Ringlet', prefix: 'RG' }),
    ).rejects.toThrow(ConflictException);
  });

  it('rejects deleting a category that still has items', async () => {
    const { service, prisma } = createService();
    prisma.category.findFirst.mockResolvedValueOnce({ id: 'cat-1' });
    prisma.inventoryItem.count.mockResolvedValueOnce(3);

    await expect(service.remove(tenantId, 'cat-1')).rejects.toThrow(
      ConflictException,
    );
    expect(prisma.category.delete).not.toHaveBeenCalled();
  });

  it('404s when updating a category from another tenant', async () => {
    const { service, prisma } = createService();
    prisma.category.findFirst.mockResolvedValueOnce(null);

    await expect(
      service.update(tenantId, 'foreign-id', { minStockThreshold: 5 }),
    ).rejects.toThrow(NotFoundException);
  });

  it('reports in-stock and total counts per category', async () => {
    const { service, prisma } = createService();
    const rows = [
      {
        id: 'cat-1',
        name: 'Ring',
        prefix: 'RG',
        minStockThreshold: 2,
        active: true,
      },
    ];
    prisma.category.findMany
      .mockResolvedValueOnce(rows) // ensureSeeded scan (has rows → no reseed of Ring)
      .mockResolvedValueOnce([]) // leftover scan
      .mockResolvedValueOnce(rows); // list read
    prisma.inventoryItem.groupBy
      .mockResolvedValueOnce([{ categoryId: 'cat-1', _count: { _all: 1 } }])
      .mockResolvedValueOnce([{ categoryId: 'cat-1', _count: { _all: 4 } }]);

    const result = await service.list(tenantId);
    const ring = result.find((c) => c.id === 'cat-1');
    expect(ring).toMatchObject({ inStockCount: 1, itemCount: 4 });
  });
});
