import { ConfigService } from '@nestjs/config';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { InventoryService } from './inventory.service';

const decimal = (value: number) => new Prisma.Decimal(value);

describe('InventoryService', () => {
  const createService = () => {
    const tx = {
      inventoryItem: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
    };
    const prisma = {
      $transaction: jest.fn((callback) => callback(tx)),
      inventoryItem: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      category: {
        findFirst: jest.fn(),
        create: jest.fn(),
      },
      dailyRate: {
        findFirst: jest.fn(),
        findMany: jest.fn(),
      },
      invoice: {
        findMany: jest.fn(),
      },
    };
    const config = {
      get: jest.fn(),
    };

    return {
      service: new InventoryService(
        prisma as unknown as PrismaService,
        config as unknown as ConfigService,
      ),
      prisma,
      tx,
    };
  };

  it('generates non-colliding INV tags for imported OCR rows', async () => {
    const { service, tx } = createService();
    tx.inventoryItem.findMany.mockResolvedValue([
      { tagNumber: 'INV-0001' },
      { tagNumber: 'INV-0003' },
    ]);
    tx.inventoryItem.create.mockImplementation(({ data }) =>
      Promise.resolve(data),
    );

    const result = await service.importItems('tenant-1', {
      rows: [
        {
          itemName: 'Gold Ring',
          metalType: 'gold',
          grossWeight: 4.5,
          netWeight: 4.2,
        },
        {
          itemName: 'Gold Chain',
          metalType: 'gold',
          grossWeight: 10,
          netWeight: 9.5,
        },
      ],
    });

    expect(result.createdCount).toBe(2);
    expect(tx.inventoryItem.create).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({
        data: expect.objectContaining({ tagNumber: 'INV-0004' }),
      }),
    );
    expect(tx.inventoryItem.create).toHaveBeenNthCalledWith(
      2,
      expect.objectContaining({
        data: expect.objectContaining({ tagNumber: 'INV-0005' }),
      }),
    );
  });

  it('ignores reviewed tags and still generates SwarnaLekh tags', async () => {
    const { service, tx } = createService();
    tx.inventoryItem.findMany.mockResolvedValue([{ tagNumber: 'INV-0001' }]);
    tx.inventoryItem.create.mockImplementation(({ data }) =>
      Promise.resolve(data),
    );

    await service.importItems('tenant-1', {
      rows: [
        {
          itemName: 'Gold Ring',
          tagNumber: 'HUID123456',
          metalType: 'gold',
          grossWeight: 4.5,
          netWeight: 4.2,
        },
      ],
    });

    expect(tx.inventoryItem.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ tagNumber: 'INV-0002' }),
      }),
    );
  });

  it('aggregates PDF inventory dashboard stats', async () => {
    const { service, prisma } = createService();
    const now = new Date();
    const olderThanNinetyDays = new Date(now);
    olderThanNinetyDays.setDate(olderThanNinetyDays.getDate() - 100);

    prisma.inventoryItem.findMany.mockResolvedValue([
      {
        metalType: 'gold',
        stockType: 'unique',
        quantity: 2,
        grossWeight: decimal(22),
        netWeight: decimal(10),
        status: 'in_stock',
        hasStones: true,
        stoneValue: decimal(15000),
        purchaseRate: decimal(6000),
        createdAt: olderThanNinetyDays,
        updatedAt: now,
      },
      {
        metalType: 'silver',
        stockType: 'bulk',
        quantity: 2,
        grossWeight: decimal(105),
        netWeight: decimal(50),
        status: 'in_stock',
        hasStones: false,
        stoneValue: decimal(0),
        purchaseRate: decimal(80),
        createdAt: now,
        updatedAt: now,
      },
      {
        metalType: 'gold',
        stockType: 'unique',
        quantity: 1,
        grossWeight: decimal(8),
        netWeight: decimal(7.5),
        status: 'sold',
        hasStones: false,
        stoneValue: decimal(0),
        purchaseRate: decimal(6000),
        createdAt: now,
        updatedAt: now,
      },
    ]);

    await expect(service.getStats('tenant-1')).resolves.toMatchObject({
      totalProducts: 3,
      inStock: 2,
      sold: 1,
      soldThisMonth: 1,
      totalGoldWeight: 20,
      totalSilverWeight: 100,
      totalDiamondStock: 1,
      alerts: {
        lowStock: 1,
        outOfStock: 1,
        highValueProducts: 0,
        unsoldProducts: 1,
      },
      metalBreakdown: [
        { metalType: 'gold', count: 1, quantity: 2, totalWeight: 20 },
        { metalType: 'silver', count: 1, quantity: 2, totalWeight: 100 },
      ],
    });
  });

  it('passes PDF search and filters to inventory listing', async () => {
    const { service, prisma } = createService();
    prisma.inventoryItem.findMany.mockResolvedValue([]);

    await service.findAll('tenant-1', {
      search: 'ring',
      categoryName: 'Ring',
      location: 'Main',
      status: 'in_stock',
      metalType: 'gold',
      dateFrom: '2026-06-01',
      dateTo: '2026-06-10',
    });

    expect(prisma.inventoryItem.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          tenantId: 'tenant-1',
          status: 'in_stock',
          metalType: 'gold',
          category: {
            name: { contains: 'Ring', mode: 'insensitive' },
          },
          location: { contains: 'Main', mode: 'insensitive' },
          OR: expect.arrayContaining([
            { itemName: { contains: 'ring', mode: 'insensitive' } },
            { barcode: { contains: 'ring', mode: 'insensitive' } },
            { tagNumber: { contains: 'ring', mode: 'insensitive' } },
          ]),
        }),
      }),
    );
  });

  it('adds product codes, categories, and selling valuation to overview items', async () => {
    const { service, prisma } = createService();
    const item = {
      id: 'item-1',
      itemName: 'Gold Ring',
      tagNumber: 'INV-0001',
      barcode: 'DES-77',
      category: { id: 'cat-1', name: 'Ring' },
      metalType: 'gold',
      karat: '22K',
      stockType: 'unique',
      quantity: 1,
      grossWeight: decimal(10),
      netWeight: decimal(9),
      makingChargesPerGram: decimal(100),
      makingChargesFixed: null,
      makingChargesPercent: null,
      wastagePercent: decimal(5),
      stoneValue: decimal(500),
      stoneDetails: { stoneWeight: 0.25 },
      purchaseRate: decimal(5500),
      sellingPrice: decimal(59000),
      status: 'in_stock',
    };

    prisma.inventoryItem.findMany.mockResolvedValue([item]);
    prisma.dailyRate.findFirst.mockResolvedValue({
      rateDate: new Date('2026-06-10T00:00:00.000Z'),
    });
    prisma.dailyRate.findMany.mockResolvedValue([
      { metalType: 'gold', karat: '22K', ratePerGram: decimal(6000) },
    ]);

    const overview = await service.getOverview('tenant-1');

    expect(overview.items[0]).toMatchObject({
      productCode: 'INV-0001',
      designNumber: 'DES-77',
      categoryName: 'Ring',
      stoneWeight: 0.25,
      currentRatePerGram: 6000,
      makingChargesValue: 900,
      calculatedSellingPrice: 58100,
      finalSellingPrice: 59000,
      sellingPrice: 59000,
      estimatedSellingPrice: 59000,
      estimatedTotalValue: 59000,
    });
  });

  it('maps invoice history to PDF sold products rows', async () => {
    const { service, prisma } = createService();
    prisma.invoice.findMany.mockResolvedValue([
      {
        id: 'invoice-1',
        invoiceNumber: 'SLK-2026-0001',
        invoiceDate: new Date('2026-06-10T00:00:00.000Z'),
        createdAt: new Date('2026-06-10T10:00:00.000Z'),
        customerName: 'Priya Singh',
        customerPhone: '+919111222333',
        paymentMode: 'upi',
        items: [
          {
            id: 'invoice-item-1',
            itemName: 'Gold Ring',
            itemTotal: decimal(58100),
            quantity: 1,
            inventoryItemId: 'item-1',
          },
        ],
      },
    ]);

    await expect(
      service.getSoldProducts('tenant-1', {
        search: 'Priya',
        dateFrom: '2026-06-01',
        dateTo: '2026-06-10',
      }),
    ).resolves.toEqual([
      {
        id: 'invoice-item-1',
        invoiceId: 'invoice-1',
        invoiceNumber: 'SLK-2026-0001',
        customerName: 'Priya Singh',
        customerPhone: '+919111222333',
        productName: 'Gold Ring',
        soldDate: new Date('2026-06-10T00:00:00.000Z'),
        sellingPrice: 58100,
        paymentMethod: 'upi',
        quantity: 1,
        inventoryItemId: 'item-1',
      },
    ]);
    expect(prisma.invoice.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          tenantId: 'tenant-1',
          deletedAt: null,
          OR: expect.arrayContaining([
            { invoiceNumber: { contains: 'Priya', mode: 'insensitive' } },
            { customerName: { contains: 'Priya', mode: 'insensitive' } },
          ]),
        }),
      }),
    );
  });

  it('saves product image payloads when creating inventory', async () => {
    const { service, prisma } = createService();
    prisma.inventoryItem.create.mockResolvedValue({ id: 'item-1' });

    await service.create('tenant-1', {
      itemName: 'Gold Ring',
      metalType: 'gold',
      grossWeight: 10,
      netWeight: 9,
      purchaseRate: 6000,
      sellingPrice: 54900,
      photoUrls: ['data:image/jpeg;base64,abcd'],
    });

    expect(prisma.inventoryItem.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          tenantId: 'tenant-1',
          sellingPrice: 54900,
          photos: ['data:image/jpeg;base64,abcd'],
        }),
      }),
    );
  });

  it('clears product image payloads when updating inventory with an empty image list', async () => {
    const { service, prisma } = createService();
    prisma.inventoryItem.findFirst.mockResolvedValue({ id: 'item-1' });
    prisma.inventoryItem.update.mockResolvedValue({ id: 'item-1' });

    await service.update('tenant-1', 'item-1', {
      itemName: 'Gold Ring',
      metalType: 'gold',
      grossWeight: 10,
      netWeight: 9,
      photoUrls: [],
    });

    expect(prisma.inventoryItem.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'item-1' },
        data: expect.objectContaining({
          photos: [],
        }),
      }),
    );
  });
});
