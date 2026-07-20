import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { InvoiceService } from './invoice.service';

const decimal = (value: number) => new Prisma.Decimal(value);

describe('InvoiceService', () => {
  const createService = () => {
    const tx = {
      $queryRaw: jest.fn().mockResolvedValue([]),
      invoice: {
        count: jest.fn(),
        create: jest.fn(),
        findFirst: jest.fn(),
        update: jest.fn(),
      },
      customer: {
        findFirst: jest.fn(),
        update: jest.fn(),
      },
      inventoryItem: {
        findFirst: jest.fn(),
        update: jest.fn(),
      },
      dailyRate: {
        findFirst: jest.fn(),
      },
      payment: {
        create: jest.fn(),
      },
    };
    const prisma = {
      $transaction: jest.fn((callback) => callback(tx)),
      invoice: {
        findMany: jest.fn(),
        count: jest.fn(),
        findFirst: jest.fn(),
      },
      payment: {
        findMany: jest.fn(),
      },
      tenant: {
        findUnique: jest.fn(),
      },
    };

    return {
      service: new InvoiceService(prisma as unknown as PrismaService),
      prisma,
      tx,
    };
  };

  it('creates an invoice and marks a unique inventory item sold', async () => {
    const { service, tx } = createService();
    tx.invoice.count.mockResolvedValue(0);
    tx.inventoryItem.findFirst.mockResolvedValue({
      id: 'item-1',
      tagNumber: 'INV-0001',
      itemName: 'Gold Ring',
      metalType: 'gold',
      karat: '22K',
      stockType: 'unique',
      quantity: 1,
      status: 'in_stock',
      grossWeight: decimal(10),
      netWeight: decimal(9),
      makingChargesFixed: decimal(500),
      makingChargesPerGram: null,
      makingChargesPercent: null,
      stoneValue: decimal(250),
      wastagePercent: decimal(0),
      hallmarkNumber: null,
      huid: null,
    });
    tx.dailyRate.findFirst.mockResolvedValue({
      ratePerGram: decimal(6000),
    });
    tx.invoice.create.mockResolvedValue({
      id: 'invoice-1',
      grandTotal: decimal(56328),
      items: [],
    });
    tx.payment.create.mockResolvedValue({ id: 'payment-1' });

    const result = await service.createInvoice('tenant-1', 'user-1', {
      customerName: 'Asha Shah',
      customerPhone: '9999999999',
      items: [{ inventoryItemId: 'item-1', quantity: 1 }],
      amountPaid: 50000,
      paymentMode: 'upi',
    });

    expect(result.id).toBe('invoice-1');
    expect(tx.inventoryItem.update).toHaveBeenCalledWith({
      where: { id: 'item-1' },
      data: { status: 'sold' },
    });
    expect(tx.invoice.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          invoiceNumber: expect.stringMatching(/^SLK-\d{4}-0001$/),
          customerName: 'Asha Shah',
          customerPhone: '9999999999',
          paymentMode: 'upi',
          items: {
            create: [
              expect.objectContaining({
                inventoryItemId: 'item-1',
                itemName: 'Gold Ring',
                quantity: 1,
                metalValue: decimal(54000),
                makingCharges: decimal(500),
                stoneValue: decimal(250),
                itemTotal: decimal(54750),
              }),
            ],
          },
        }),
      }),
    );
    expect(tx.payment.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          amount: 50000,
          paymentMode: 'upi',
        }),
      }),
    );
  });

  it('prices a karat-less item from any rate set for its metal', async () => {
    const { service, tx } = createService();
    tx.invoice.count.mockResolvedValue(0);
    tx.inventoryItem.findFirst.mockResolvedValue({
      id: 'item-1',
      tagNumber: null,
      itemName: 'test',
      metalType: 'gold',
      karat: null, // no karat on the item
      stockType: 'unique',
      quantity: 1,
      status: 'in_stock',
      grossWeight: decimal(1),
      netWeight: decimal(1),
      makingChargesFixed: null,
      makingChargesPerGram: null,
      makingChargesPercent: null,
      stoneValue: decimal(0),
      wastagePercent: decimal(0),
      hallmarkNumber: null,
      huid: null,
    });
    // Rate exists only under a specific karat (Gold 22K): a karat-filtered
    // lookup misses, the metal-wide (no karat filter) lookup must find it.
    tx.dailyRate.findFirst.mockImplementation(({ where }: any) =>
      Promise.resolve(
        'karat' in where ? null : { ratePerGram: decimal(15000) },
      ),
    );
    tx.invoice.create.mockResolvedValue({
      id: 'invoice-1',
      grandTotal: decimal(15450),
      items: [],
    });
    tx.payment.create.mockResolvedValue({ id: 'payment-1' });

    await expect(
      service.createInvoice('tenant-1', 'user-1', {
        customerName: 'Walk-in',
        items: [{ inventoryItemId: 'item-1', quantity: 1 }],
        paymentMode: 'cash',
      }),
    ).resolves.toEqual(expect.objectContaining({ id: 'invoice-1' }));

    expect(tx.inventoryItem.update).toHaveBeenCalledWith({
      where: { id: 'item-1' },
      data: { status: 'sold' },
    });
  });

  it('uses explicit inventory selling price as the billing line price', async () => {
    const { service, tx } = createService();
    tx.invoice.count.mockResolvedValue(0);
    tx.inventoryItem.findFirst.mockResolvedValue({
      id: 'item-1',
      tagNumber: 'INV-0001',
      itemName: 'Gold Ring',
      metalType: 'gold',
      karat: '22K',
      stockType: 'unique',
      quantity: 1,
      status: 'in_stock',
      grossWeight: decimal(10),
      netWeight: decimal(9),
      purchaseRate: decimal(6000),
      sellingPrice: decimal(59000),
      makingChargesFixed: decimal(500),
      makingChargesPerGram: null,
      makingChargesPercent: null,
      stoneValue: decimal(250),
      wastagePercent: decimal(0),
      hallmarkNumber: null,
      huid: null,
    });
    tx.invoice.create.mockResolvedValue({
      id: 'invoice-1',
      grandTotal: decimal(60770),
      items: [],
    });

    await service.createInvoice('tenant-1', 'user-1', {
      customerName: 'Asha Shah',
      items: [{ inventoryItemId: 'item-1', quantity: 1 }],
      paymentMode: 'cash',
    });

    expect(tx.dailyRate.findFirst).not.toHaveBeenCalled();
    expect(tx.invoice.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          subtotal: decimal(59000),
          taxableAmount: decimal(59000),
          totalTax: decimal(1770),
          grandTotal: decimal(60770),
          balanceDue: 60770,
          items: {
            create: [
              expect.objectContaining({
                inventoryItemId: 'item-1',
                ratePerGram: null,
                metalValue: decimal(58250),
                makingCharges: decimal(500),
                stoneValue: decimal(250),
                itemTotal: decimal(59000),
              }),
            ],
          },
        }),
      }),
    );
  });

  it('reduces bulk inventory quantity after invoice generation', async () => {
    const { service, tx } = createService();
    tx.invoice.count.mockResolvedValue(4);
    tx.inventoryItem.findFirst.mockResolvedValue({
      id: 'item-2',
      tagNumber: 'INV-0002',
      itemName: 'Silver Coin',
      metalType: 'silver',
      karat: '925',
      stockType: 'bulk',
      quantity: 5,
      status: 'in_stock',
      grossWeight: decimal(10),
      netWeight: decimal(10),
      makingChargesFixed: null,
      makingChargesPerGram: null,
      makingChargesPercent: null,
      stoneValue: decimal(0),
      wastagePercent: decimal(0),
      hallmarkNumber: null,
      huid: null,
    });
    tx.dailyRate.findFirst.mockResolvedValue({ ratePerGram: decimal(80) });
    tx.invoice.create.mockResolvedValue({
      id: 'invoice-2',
      grandTotal: decimal(4944),
      items: [],
    });

    await service.createInvoice('tenant-1', 'user-1', {
      customerName: 'Walk In',
      items: [{ inventoryItemId: 'item-2', quantity: 2 }],
      paymentMode: 'cash',
    });

    expect(tx.inventoryItem.update).toHaveBeenCalledWith({
      where: { id: 'item-2' },
      data: { quantity: 3, status: 'in_stock' },
    });
  });

  it('rejects invoices without customer details or selected inventory', async () => {
    const { service, tx } = createService();
    tx.invoice.count.mockResolvedValue(0);

    await expect(
      service.createInvoice('tenant-1', 'user-1', { items: [] }),
    ).rejects.toThrow(BadRequestException);
  });

  it('locks the inventory row FOR UPDATE before selling it', async () => {
    const { service, tx } = createService();
    tx.invoice.count.mockResolvedValue(0);
    tx.inventoryItem.findFirst.mockResolvedValue({
      id: 'item-1',
      tagNumber: 'INV-0001',
      itemName: 'Gold Ring',
      metalType: 'gold',
      karat: '22K',
      stockType: 'unique',
      quantity: 1,
      status: 'in_stock',
      grossWeight: decimal(10),
      netWeight: decimal(9),
      sellingPrice: decimal(59000),
      wastagePercent: decimal(0),
      stoneValue: decimal(0),
      makingChargesFixed: null,
      makingChargesPerGram: null,
      makingChargesPercent: null,
      hallmarkNumber: null,
      huid: null,
    });
    tx.invoice.create.mockResolvedValue({
      id: 'invoice-1',
      grandTotal: decimal(60770),
      items: [],
    });

    await service.createInvoice('tenant-1', 'user-1', {
      customerName: 'Asha',
      items: [{ inventoryItemId: 'item-1', quantity: 1 }],
      paymentMode: 'cash',
    });

    expect(tx.$queryRaw).toHaveBeenCalled();
  });

  it('previews server-computed totals without persisting or reducing stock', async () => {
    const { service, tx } = createService();
    tx.inventoryItem.findFirst.mockResolvedValue({
      id: 'item-1',
      tagNumber: 'INV-0001',
      itemName: 'Gold Ring',
      metalType: 'gold',
      karat: '22K',
      stockType: 'unique',
      quantity: 1,
      status: 'in_stock',
      grossWeight: decimal(10),
      netWeight: decimal(9),
      sellingPrice: decimal(59000),
      wastagePercent: decimal(0),
      stoneValue: decimal(250),
      makingChargesFixed: decimal(500),
      makingChargesPerGram: null,
      makingChargesPercent: null,
      hallmarkNumber: null,
      huid: null,
    });

    const preview = await service.previewInvoice('tenant-1', {
      customerName: 'Asha',
      items: [{ inventoryItemId: 'item-1', quantity: 1 }],
    });

    expect(preview.grandTotal).toBe(60770);
    expect(preview.items[0].itemTotal).toBe(59000);
    // Preview must not lock, persist, or reduce stock.
    expect(tx.$queryRaw).not.toHaveBeenCalled();
    expect(tx.invoice.create).not.toHaveBeenCalled();
    expect(tx.inventoryItem.update).not.toHaveBeenCalled();
  });

  it('prices a rate-based line from the gold rate, making, and GST typed on the bill', async () => {
    const { service, tx } = createService();
    tx.inventoryItem.findFirst.mockResolvedValue({
      id: 'item-1',
      tagNumber: 'INV-0001',
      itemName: 'Gold Chain',
      metalType: 'gold',
      karat: '22K',
      stockType: 'unique',
      quantity: 1,
      status: 'in_stock',
      grossWeight: decimal(10),
      netWeight: decimal(9),
      purchaseRate: decimal(5000),
      // No selling price and no daily rate: the bill's own rate must price it.
      makingChargesFixed: null,
      makingChargesPerGram: null,
      makingChargesPercent: null,
      stoneValue: decimal(0),
      wastagePercent: decimal(0),
      hallmarkNumber: null,
      huid: null,
    });

    const preview = await service.previewInvoice('tenant-1', {
      customerName: 'Walk-in',
      customerAddress: '12 MG Road, Surat',
      ratePerGramOverride: 6000,
      makingPerGramOverride: 200,
      gstPercentOverride: 5,
      items: [{ inventoryItemId: 'item-1', quantity: 1 }],
    });

    // metal 9*6000=54000, making 200*10=2000 → line 56000.
    expect(preview.items[0].metalValue).toBe(54000);
    expect(preview.items[0].makingCharges).toBe(2000);
    expect(preview.items[0].itemTotal).toBe(56000);
    // GST 5% of 56000 = 2800 → grand total 58800.
    expect(preview.totalTax).toBe(2800);
    expect(preview.grandTotal).toBe(58800);
    expect(preview.customerAddress).toBe('12 MG Road, Surat');
    // The typed rate replaces the daily-rate lookup entirely.
    expect(tx.dailyRate.findFirst).not.toHaveBeenCalled();
  });

  it('returns the existing invoice for a repeated idempotency key', async () => {
    const { service, prisma } = createService();
    prisma.invoice.findFirst.mockResolvedValue({
      id: 'existing-invoice',
      items: [],
    });

    const result = await service.createInvoice('tenant-1', 'user-1', {
      customerName: 'Asha',
      items: [{ inventoryItemId: 'item-1' }],
      idempotencyKey: 'idem-123',
    });

    expect(result.id).toBe('existing-invoice');
    // Short-circuits before opening a transaction.
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('aggregates billing dashboard metrics', async () => {
    const { service, prisma } = createService();
    prisma.invoice.findMany
      .mockResolvedValueOnce([
        { grandTotal: decimal(10000) },
        { grandTotal: decimal(5000) },
      ])
      .mockResolvedValueOnce([
        {
          grandTotal: decimal(10000),
          items: [{ itemName: 'Gold Ring', quantity: 1 }],
        },
        {
          grandTotal: decimal(5000),
          items: [{ itemName: 'Gold Ring', quantity: 2 }],
        },
        {
          grandTotal: decimal(15000),
          items: [{ itemName: 'Silver Coin', quantity: 4 }],
        },
      ]);
    prisma.invoice.count.mockResolvedValue(9);

    await expect(service.getDashboard('tenant-1')).resolves.toEqual({
      todaysRevenue: 15000,
      monthlyRevenue: 30000,
      totalBills: 9,
      averageBillValue: 10000,
      topSellingProducts: [
        { itemName: 'Silver Coin', quantity: 4 },
        { itemName: 'Gold Ring', quantity: 3 },
      ],
    });
  });

  it('filters invoice history by search and date', async () => {
    const { service, prisma } = createService();
    prisma.invoice.findMany.mockResolvedValue([]);

    await service.findAll('tenant-1', {
      search: 'Asha',
      dateFrom: '2026-06-01',
      dateTo: '2026-06-10',
    });

    expect(prisma.invoice.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          tenantId: 'tenant-1',
          deletedAt: null,
          invoiceDate: {
            gte: new Date('2026-06-01T00:00:00.000Z'),
            lte: new Date('2026-06-10T23:59:59.999Z'),
          },
          OR: expect.arrayContaining([
            { invoiceNumber: { contains: 'Asha', mode: 'insensitive' } },
            { customerName: { contains: 'Asha', mode: 'insensitive' } },
            { customerPhone: { contains: 'Asha', mode: 'insensitive' } },
          ]),
        }),
      }),
    );
  });

  it('keeps invoice history unfiltered when search and dates are blank', async () => {
    const { service, prisma } = createService();
    prisma.invoice.findMany.mockResolvedValue([]);

    await service.findAll('tenant-1', {
      search: '   ',
      dateFrom: '',
      dateTo: 'not-a-date',
    });

    expect(prisma.invoice.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          tenantId: 'tenant-1',
          deletedAt: null,
        },
      }),
    );
  });

  it('builds printable invoice data with shop, GST, and protection details', async () => {
    const { service, prisma } = createService();
    prisma.invoice.findFirst.mockResolvedValue(invoiceDetailFixture());
    prisma.tenant.findUnique.mockResolvedValue(tenantFixture());

    const printable = await service.getPrintableInvoice(
      'tenant-1',
      'invoice-1',
    );

    expect(prisma.invoice.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'invoice-1', tenantId: 'tenant-1', deletedAt: null },
      }),
    );
    expect(printable.shop.name).toBe('RK Jewellers');
    expect(printable.invoice.invoiceNumber).toBe('SLK-2026-0001');
    expect(printable.invoice.items).toEqual([
      expect.objectContaining({
        itemName: 'Gold Ring',
        netWeight: 9,
        makingCharges: 500,
        itemTotal: 54750,
      }),
    ]);
    expect(printable.invoice.cgstAmount).toBe(821.25);
    expect(printable.invoice.sgstAmount).toBe(821.25);
    expect(printable.qrPayload).toContain('Invoice:SLK-2026-0001');
    expect(printable.verificationCode).toMatch(/^[A-F0-9]{12}$/);
  });

  it('generates a base64 PDF payload for invoice download and reprint', async () => {
    const { service, prisma } = createService();
    prisma.invoice.findFirst.mockResolvedValue(invoiceDetailFixture());
    prisma.tenant.findUnique.mockResolvedValue(tenantFixture());

    const pdf = await service.getInvoicePdf('tenant-1', 'invoice-1');
    const bytes = Buffer.from(pdf.base64, 'base64');
    const text = bytes.toString('utf8');

    expect(pdf.fileName).toBe('SLK-2026-0001.pdf');
    expect(pdf.mimeType).toBe('application/pdf');
    expect(pdf.byteLength).toBe(bytes.byteLength);
    expect(text.startsWith('%PDF-1.4')).toBe(true);
    expect(text).toContain('SLK-2026-0001');
    expect(text).toContain('GST Breakdown');
  });

  it('embeds a shop logo data image in the invoice PDF', async () => {
    const { service, prisma } = createService();
    prisma.invoice.findFirst.mockResolvedValue(invoiceDetailFixture());
    prisma.tenant.findUnique.mockResolvedValue({
      ...tenantFixture(),
      logoUrl: `data:image/jpeg;base64,${jpegLogoBase64()}`,
    });

    const pdf = await service.getInvoicePdf('tenant-1', 'invoice-1');
    const text = Buffer.from(pdf.base64, 'base64').toString('utf8');

    expect(text).toContain('/Subtype /Image');
    expect(text).toContain('/DCTDecode');
    expect(text).toContain('/Logo Do');
    expect(text).toContain('Shop Logo: Embedded');
  });

  it('generates a WhatsApp share payload for invoice history', async () => {
    const { service, prisma } = createService();
    prisma.invoice.findFirst.mockResolvedValue(invoiceDetailFixture());
    prisma.tenant.findUnique.mockResolvedValue(tenantFixture());

    const share = await service.getInvoiceShare('tenant-1', 'invoice-1');
    const shareUrl = new URL(share.whatsappUrl);

    expect(share.whatsappText).toContain('RK Jewellers Invoice');
    expect(share.whatsappText).toContain('Invoice No: SLK-2026-0001');
    expect(share.whatsappText).toContain('GST: ₹1642.50');
    expect(shareUrl.hostname).toBe('wa.me');
    expect(shareUrl.searchParams.get('text')).toBe(share.whatsappText);
    expect(share.verificationCode).toMatch(/^[A-F0-9]{12}$/);
  });

  describe('addPayment', () => {
    const invoiceRow = (over: Record<string, unknown> = {}) => ({
      id: 'inv-1',
      customerId: 'cust-1',
      grandTotal: decimal(10000),
      amountPaid: decimal(3000),
      balanceDue: decimal(7000),
      paymentMode: 'cash',
      ...over,
    });

    it('records a partial payment and moves the balance', async () => {
      const { service, tx } = createService();
      tx.invoice.findFirst.mockResolvedValue(invoiceRow());
      tx.payment.create.mockResolvedValue({
        id: 'pay-1',
        amount: decimal(4000),
        paymentMode: 'upi',
        paymentDate: new Date('2026-06-11'),
        referenceNumber: 'TXN-9',
        notes: null,
        createdAt: new Date('2026-06-11'),
      });
      tx.invoice.update.mockResolvedValue({
        id: 'inv-1',
        grandTotal: decimal(10000),
        amountPaid: decimal(7000),
        balanceDue: decimal(3000),
      });

      const result = await service.addPayment('tenant-1', 'inv-1', {
        amount: 4000,
        paymentMode: 'upi',
        referenceNumber: 'TXN-9',
      });

      expect(tx.payment.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            tenantId: 'tenant-1',
            invoiceId: 'inv-1',
            customerId: 'cust-1',
            paymentMode: 'upi',
          }),
        }),
      );
      expect(tx.invoice.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'inv-1' },
          data: expect.objectContaining({
            amountPaid: expect.anything(),
            balanceDue: expect.anything(),
          }),
        }),
      );
      expect(result.invoice.amountPaid).toBe(7000);
      expect(result.invoice.balanceDue).toBe(3000);
      expect(result.payment.amount).toBe(4000);
    });

    it('rejects a payment that exceeds the balance due', async () => {
      const { service, tx } = createService();
      tx.invoice.findFirst.mockResolvedValue(invoiceRow());

      await expect(
        service.addPayment('tenant-1', 'inv-1', { amount: 9000 }),
      ).rejects.toThrow(BadRequestException);
      expect(tx.payment.create).not.toHaveBeenCalled();
    });

    it('rejects a non-positive payment', async () => {
      const { service, tx } = createService();
      tx.invoice.findFirst.mockResolvedValue(invoiceRow());

      await expect(
        service.addPayment('tenant-1', 'inv-1', { amount: 0 }),
      ).rejects.toThrow(BadRequestException);
    });

    it('throws when the invoice is not found for the tenant', async () => {
      const { service, tx } = createService();
      tx.invoice.findFirst.mockResolvedValue(null);

      await expect(
        service.addPayment('tenant-1', 'missing', { amount: 100 }),
      ).rejects.toThrow(NotFoundException);
    });
  });
});

function tenantFixture() {
  return {
    shopName: 'RK Jewellers',
    ownerName: 'Ravi Kumar',
    phone: '9999999999',
    email: 'billing@example.com',
    address: 'MG Road',
    city: 'Ahmedabad',
    state: 'Gujarat',
    pincode: '380001',
    gstin: '24ABCDE1234F1Z5',
    pan: 'ABCDE1234F',
    logoUrl: 'https://example.com/logo.png',
  };
}

function jpegLogoBase64() {
  return Buffer.from([
    0xff, 0xd8, 0xff, 0xc0, 0x00, 0x11, 0x08, 0x00, 0x01, 0x00, 0x01, 0x03,
    0x01, 0x11, 0x00, 0x02, 0x11, 0x00, 0x03, 0x11, 0x00, 0xff, 0xd9,
  ]).toString('base64');
}

function invoiceDetailFixture() {
  return {
    id: 'invoice-1',
    invoiceNumber: 'SLK-2026-0001',
    invoiceDate: new Date('2026-06-10T00:00:00.000Z'),
    customerName: 'Asha Shah',
    customerPhone: '9999999999',
    customerGstin: null,
    paymentMode: 'upi',
    subtotal: decimal(54750),
    totalMakingCharges: decimal(500),
    totalStoneValue: decimal(250),
    discountAmount: decimal(0),
    oldGoldValue: decimal(0),
    taxableAmount: decimal(54750),
    cgstPercent: decimal(1.5),
    cgstAmount: decimal(821.25),
    sgstPercent: decimal(1.5),
    sgstAmount: decimal(821.25),
    igstPercent: decimal(0),
    igstAmount: decimal(0),
    totalTax: decimal(1642.5),
    grandTotal: decimal(56393),
    roundOff: decimal(0.5),
    amountPaid: decimal(50000),
    balanceDue: decimal(6393),
    notes: 'Paid through UPI',
    customer: null,
    creator: { id: 'user-1', name: 'Ravi Kumar' },
    payments: [],
    items: [
      {
        id: 'invoice-item-1',
        invoiceId: 'invoice-1',
        inventoryItemId: 'item-1',
        itemName: 'Gold Ring',
        quantity: 1,
        metalType: 'gold',
        karat: '22K',
        grossWeight: decimal(10),
        netWeight: decimal(9),
        ratePerGram: decimal(6000),
        metalValue: decimal(54000),
        makingCharges: decimal(500),
        stoneValue: decimal(250),
        wastageValue: decimal(0),
        hallmarkNumber: 'HM-1',
        huid: 'HUID123',
        itemTotal: decimal(54750),
      },
    ],
  };
}
