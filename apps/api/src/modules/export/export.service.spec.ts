import { BadRequestException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { ExportService } from './export.service';

const decimal = (v: number) => new Prisma.Decimal(v);

const createService = () => {
  const prisma = {
    invoice: { findMany: jest.fn() },
    inventoryItem: { findMany: jest.fn() },
    customer: { findMany: jest.fn() },
    auditLog: { findMany: jest.fn() },
  };
  return {
    prisma,
    service: new ExportService(prisma as unknown as PrismaService),
  };
};

const decode = (base64: string) =>
  Buffer.from(base64, 'base64').toString('utf8');

describe('ExportService', () => {
  it('exports invoices as CSV with a header row and formatted values', async () => {
    const { service, prisma } = createService();
    prisma.invoice.findMany.mockResolvedValue([
      {
        invoiceNumber: 'SLK-2026-0001',
        invoiceDate: new Date('2026-06-10T00:00:00.000Z'),
        customerName: 'Doe, John',
        customerPhone: '99999',
        subtotal: decimal(10000),
        discountAmount: decimal(500),
        totalTax: decimal(285),
        grandTotal: decimal(9785),
        amountPaid: decimal(5000),
        balanceDue: decimal(4785),
        paymentMode: 'upi',
        _count: { items: 3 },
      },
    ]);

    const payload = await service.export('tenant-1', 'invoices', {});
    expect(payload.mimeType).toBe('text/csv');
    expect(payload.fileName).toMatch(/^invoices-\d{4}-\d{2}-\d{2}\.csv$/);
    expect(payload.rowCount).toBe(1);

    const csv = decode(payload.base64);
    expect(csv).toContain('Invoice No,Date,Customer');
    expect(csv).toContain('SLK-2026-0001');
    // Comma inside the customer name must be quoted.
    expect(csv).toContain('"Doe, John"');
    expect(csv).toContain('9785');
  });

  it('applies the tenant scope, soft-delete filter and date range', async () => {
    const { service, prisma } = createService();
    prisma.invoice.findMany.mockResolvedValue([]);

    await service.export('tenant-9', 'invoices', {
      dateFrom: '2026-06-01',
      dateTo: '2026-06-30',
    });

    const where = prisma.invoice.findMany.mock.calls[0][0].where;
    expect(where.tenantId).toBe('tenant-9');
    expect(where.deletedAt).toBeNull();
    expect(where.invoiceDate.gte).toBeInstanceOf(Date);
    expect(where.invoiceDate.lte).toBeInstanceOf(Date);
  });

  it('exports inventory with a category column', async () => {
    const { service, prisma } = createService();
    prisma.inventoryItem.findMany.mockResolvedValue([
      {
        tagNumber: 'TAG-1',
        itemName: 'Ring',
        category: { name: 'Rings' },
        metalType: 'gold',
        karat: '22K',
        grossWeight: decimal(10),
        netWeight: decimal(9),
        quantity: 1,
        status: 'in_stock',
        sellingPrice: decimal(60000),
      },
    ]);

    const payload = await service.export('tenant-1', 'inventory', {
      status: 'in_stock',
    });
    const csv = decode(payload.base64);
    expect(csv).toContain('Tag,Item,Category');
    expect(csv).toContain('TAG-1,Ring,Rings,gold,22K');
    expect(prisma.inventoryItem.findMany.mock.calls[0][0].where.status).toBe(
      'in_stock',
    );
  });

  it('rejects an unknown export type', async () => {
    const { service } = createService();
    await expect(service.export('tenant-1', 'bogus', {})).rejects.toThrow(
      BadRequestException,
    );
  });
});
