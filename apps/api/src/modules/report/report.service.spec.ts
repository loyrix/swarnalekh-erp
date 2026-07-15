import { BadRequestException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { ReportService } from './report.service';

const decimal = (value: number) => new Prisma.Decimal(value);

describe('ReportService', () => {
  const createService = () => {
    const prisma = {
      inventoryItem: {
        findMany: jest.fn(),
      },
      invoice: {
        findMany: jest.fn(),
      },
      mortgageLoan: {
        findMany: jest.fn(),
      },
      tenant: {
        findUnique: jest.fn(),
      },
    };

    return {
      service: new ReportService(prisma as unknown as PrismaService),
      prisma,
    };
  };

  const seedReportMocks = (
    prisma: ReturnType<typeof createService>['prisma'],
  ) => {
    prisma.inventoryItem.findMany.mockResolvedValue([
      {
        id: 'item-1',
        itemName: 'Gold Ring',
        tagNumber: 'INV-0001',
        barcode: 'DES-77',
        category: { name: 'Ring' },
        metalType: 'gold',
        karat: '22K',
        purity: null,
        grossWeight: decimal(10),
        netWeight: decimal(9),
        quantity: 1,
        stockType: 'unique',
        status: 'in_stock',
        location: 'Main Branch',
        sellingPrice: decimal(59000),
        purchaseRate: decimal(6000),
        makingChargesPerGram: decimal(100),
        makingChargesFixed: null,
        makingChargesPercent: null,
        stoneValue: decimal(0),
        wastagePercent: decimal(0),
      },
      {
        id: 'item-2',
        itemName: 'Silver Chain',
        tagNumber: 'INV-0002',
        barcode: 'DES-88',
        category: { name: 'Chain' },
        metalType: 'silver',
        karat: '925',
        purity: null,
        grossWeight: decimal(20),
        netWeight: decimal(18),
        quantity: 2,
        stockType: 'bulk',
        status: 'in_stock',
        location: 'Main Branch',
        sellingPrice: null,
        purchaseRate: decimal(80),
        makingChargesPerGram: decimal(10),
        makingChargesFixed: null,
        makingChargesPercent: null,
        stoneValue: decimal(0),
        wastagePercent: decimal(0),
      },
    ]);
    prisma.invoice.findMany.mockResolvedValue([
      {
        id: 'invoice-1',
        invoiceNumber: 'SLK-2026-0001',
        invoiceDate: new Date('2026-06-10T00:00:00.000Z'),
        createdAt: new Date('2026-06-10T09:00:00.000Z'),
        customerName: 'Priya Singh',
        customerPhone: '+919111222333',
        paymentMode: 'upi',
        taxableAmount: decimal(55000),
        cgstAmount: decimal(825),
        sgstAmount: decimal(825),
        igstAmount: decimal(0),
        totalTax: decimal(1650),
        grandTotal: decimal(56650),
        items: [
          {
            id: 'invoice-item-1',
            itemName: 'Gold Ring',
            quantity: 1,
            grossWeight: decimal(10),
            netWeight: decimal(9),
            ratePerGram: decimal(6000),
            metalValue: decimal(54000),
            makingCharges: decimal(1000),
            stoneValue: decimal(0),
            itemTotal: decimal(55000),
          },
        ],
      },
    ]);
    prisma.mortgageLoan.findMany.mockResolvedValue([
      {
        id: 'loan-1',
        loanNumber: 'ML-2026-0001',
        customerName: 'Asha Shah',
        customerPhone: '+919999000111',
        principalAmount: decimal(100000),
        interestRateMonthly: decimal(2),
        loanDate: new Date('2026-06-01T00:00:00.000Z'),
        totalInterestPaid: decimal(2000),
        totalPrincipalPaid: decimal(0),
        status: 'active',
        closedAt: null,
        payments: [
          {
            id: 'payment-1',
            receiptNumber: 'MR-2026-0001',
            paymentDate: new Date('2026-06-10T00:00:00.000Z'),
            amount: decimal(2000),
            paymentType: 'interest',
            paymentMode: 'cash',
            createdAt: new Date('2026-06-10T10:00:00.000Z'),
          },
        ],
      },
    ]);
  };

  it('returns PDF report groups from backend-owned data', async () => {
    const { service, prisma } = createService();
    seedReportMocks(prisma);

    const overview = await service.getOverview('tenant-1', {
      search: 'Ring',
      dateFrom: '2026-06-10',
      dateTo: '2026-06-10',
      branch: 'Main',
    });

    expect(overview.reports.currentStock).toHaveLength(2);
    expect(overview.reports.lowStock).toHaveLength(1);
    expect(overview.reports.soldProducts[0]).toMatchObject({
      invoiceNumber: 'SLK-2026-0001',
      customerName: 'Priya Singh',
      productName: 'Gold Ring',
      sellingPrice: 55000,
      paymentMode: 'upi',
    });
    expect(overview.reports.dailySales[0]).toMatchObject({
      invoiceNumber: 'SLK-2026-0001',
      grandTotal: 56650,
      totalTax: 1650,
    });
    expect(overview.reports.interestCollection[0]).toMatchObject({
      receiptNumber: 'MR-2026-0001',
      customerName: 'Asha Shah',
      amount: 2000,
      paymentMode: 'cash',
    });
    expect(overview.summary.billing).toMatchObject({
      dailySalesTotal: 56650,
      monthlySalesTotal: 56650,
      gstTotal: 1650,
    });
    expect(prisma.inventoryItem.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          tenantId: 'tenant-1',
          location: { contains: 'Main', mode: 'insensitive' },
        }),
      }),
    );
  });

  it('exports a PDF payload for a selected report', async () => {
    const { service, prisma } = createService();
    seedReportMocks(prisma);
    prisma.tenant.findUnique.mockResolvedValue({ shopName: 'My Shop' });

    const exportPayload = await service.getExport('tenant-1', 'sold-products', {
      dateFrom: '2026-06-10',
    });
    const pdf = Buffer.from(exportPayload.base64, 'base64').toString('utf8');

    expect(exportPayload).toMatchObject({
      reportType: 'sold-products',
      title: 'Sold Products Report',
      mimeType: 'application/pdf',
      rowCount: 1,
    });
    expect(exportPayload.fileName).toContain('sold-products');
    expect(pdf.startsWith('%PDF-1.4')).toBe(true);
    // Title renders uppercase under the shop letterhead.
    expect(pdf).toContain('SOLD PRODUCTS REPORT');
    expect(pdf).toContain('SLK-2026-0001');
    // Letterhead + aligned table fonts are embedded.
    expect(pdf).toContain('Helvetica-Bold');
    expect(pdf).toContain('Courier');
  });

  it('rejects unsupported report export types', async () => {
    const { service } = createService();

    await expect(service.getExport('tenant-1', 'random')).rejects.toThrow(
      BadRequestException,
    );
  });
});
