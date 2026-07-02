import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { SearchService } from './search.service';

const decimal = (v: number) => new Prisma.Decimal(v);

const createService = () => {
  const prisma = {
    customer: { findMany: jest.fn().mockResolvedValue([]) },
    inventoryItem: { findMany: jest.fn().mockResolvedValue([]) },
    invoice: { findMany: jest.fn().mockResolvedValue([]) },
  };
  return {
    prisma,
    service: new SearchService(prisma as unknown as PrismaService),
  };
};

describe('SearchService', () => {
  it('returns empty groups for a blank query without hitting the db', async () => {
    const { service, prisma } = createService();
    const result = await service.search('tenant-1', { q: '   ' });
    expect(result.total).toBe(0);
    expect(result.customers).toEqual([]);
    expect(prisma.customer.findMany).not.toHaveBeenCalled();
  });

  it('scopes every entity query to the tenant and excludes soft-deleted rows', async () => {
    const { service, prisma } = createService();
    await service.search('tenant-9', { q: 'ring' });

    for (const model of [prisma.customer, prisma.inventoryItem]) {
      const where = model.findMany.mock.calls[0][0].where;
      expect(where.tenantId).toBe('tenant-9');
      expect(where.deletedAt).toBeNull();
    }
    const invWhere = prisma.invoice.findMany.mock.calls[0][0].where;
    expect(invWhere.tenantId).toBe('tenant-9');
    expect(invWhere.deletedAt).toBeNull();
  });

  it('ranks exact and prefix matches above plain substring matches', async () => {
    const { service, prisma } = createService();
    prisma.inventoryItem.findMany.mockResolvedValue([
      {
        id: 'sub',
        tagNumber: 'X-RING-42',
        itemName: 'Bracelet',
        category: null,
        metalType: 'gold',
        status: 'in_stock',
        sellingPrice: decimal(100),
      },
      {
        id: 'exact',
        tagNumber: 'RING',
        itemName: null,
        category: null,
        metalType: 'gold',
        status: 'in_stock',
        sellingPrice: decimal(100),
      },
      {
        id: 'prefix',
        tagNumber: 'RING-7',
        itemName: null,
        category: null,
        metalType: 'gold',
        status: 'in_stock',
        sellingPrice: decimal(100),
      },
    ]);

    const result = await service.search('tenant-1', { q: 'ring' });
    expect(result.inventory.map((h) => h.id)).toEqual([
      'exact',
      'prefix',
      'sub',
    ]);
  });

  it('trims each group to the requested limit and reports total', async () => {
    const { service, prisma } = createService();
    prisma.customer.findMany.mockResolvedValue([
      {
        id: 'a',
        name: 'Aay',
        phone: null,
        altPhone: null,
        email: null,
        city: null,
      },
      {
        id: 'b',
        name: 'Aby',
        phone: null,
        altPhone: null,
        email: null,
        city: null,
      },
      {
        id: 'c',
        name: 'Acy',
        phone: null,
        altPhone: null,
        email: null,
        city: null,
      },
    ]);

    const result = await service.search('tenant-1', { q: 'a', limit: 2 });
    expect(result.customers).toHaveLength(2);
    expect(result.total).toBe(2);
    // limit drives the db `take` (limit * multiplier).
    expect(prisma.customer.findMany.mock.calls[0][0].take).toBe(8);
  });

  it('maps invoice decimals to plain numbers and formats the date', async () => {
    const { service, prisma } = createService();
    prisma.invoice.findMany.mockResolvedValue([
      {
        id: 'inv',
        invoiceNumber: 'SLK-2026-0001',
        customerName: 'Ring Buyer',
        customerPhone: '99999',
        invoiceDate: new Date('2026-06-10T00:00:00.000Z'),
        grandTotal: decimal(9785),
        balanceDue: decimal(4785),
      },
    ]);

    const result = await service.search('tenant-1', { q: 'SLK' });
    expect(result.invoices[0]).toMatchObject({
      id: 'inv',
      invoiceNumber: 'SLK-2026-0001',
      invoiceDate: '2026-06-10',
      grandTotal: 9785,
      balanceDue: 4785,
    });
  });
});
