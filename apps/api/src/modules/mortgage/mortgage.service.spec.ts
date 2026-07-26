import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { MortgageService } from './mortgage.service';

const decimal = (value: number) => new Prisma.Decimal(value);

const todayUtc = () => {
  const now = new Date();
  return new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  );
};

const makeLoan = (overrides: Record<string, unknown> = {}) => {
  const loanDate = todayUtc();
  const createdAt = new Date(loanDate);

  return {
    id: 'loan-1',
    tenantId: 'tenant-1',
    loanNumber: 'ML-2026-0001',
    customerId: 'customer-1',
    customerName: 'Priya Shah',
    customerPhone: '+919111222333',
    customerAddress: 'Mumbai',
    aadhaarNumber: '1234 5678 9012',
    panNumber: 'ABCDE1234F',
    photoIdUrl: 'data:image/jpeg;base64,cGhvdG8taWQ=',
    customerPhotoUrl: 'data:image/jpeg;base64,Y3VzdG9tZXI=',
    principalAmount: decimal(100000),
    interestRateMonthly: decimal(2),
    monthlyInterestAmount: decimal(2000),
    loanDate,
    dueDate: new Date(
      Date.UTC(
        loanDate.getUTCFullYear(),
        loanDate.getUTCMonth() + 1,
        loanDate.getUTCDate(),
      ),
    ),
    totalInterestPaid: decimal(0),
    totalPrincipalPaid: decimal(0),
    pendingInterestAmount: decimal(0),
    outstandingPrincipal: decimal(100000),
    totalPayableAmount: decimal(100000),
    status: 'active',
    notes: null,
    closedAt: null,
    closedBy: null,
    createdBy: 'user-1',
    deletedAt: null,
    createdAt,
    updatedAt: createdAt,
    customer: {
      id: 'customer-1',
      name: 'Priya Shah',
      phone: '+919111222333',
      address: 'Mumbai',
    },
    creator: { id: 'user-1', name: 'Owner' },
    closer: null,
    ornaments: [],
    payments: [],
    topups: [],
    ...overrides,
  };
};

describe('MortgageService', () => {
  const createService = () => {
    const tx = {
      customer: {
        findFirst: jest.fn(),
        create: jest.fn(),
      },
      mortgageLoan: {
        count: jest.fn(),
        create: jest.fn(),
        findFirst: jest.fn(),
        update: jest.fn(),
      },
      mortgagePayment: {
        count: jest.fn(),
        create: jest.fn(),
        findFirst: jest.fn(),
        update: jest.fn(),
        deleteMany: jest.fn(),
      },
      mortgageTopup: {
        create: jest.fn(),
      },
      tenant: {
        findUnique: jest
          .fn()
          .mockResolvedValue({ mortgageTopupMode: 'separate' }),
      },
    };
    const prisma = {
      $transaction: jest.fn((callback) => callback(tx)),
      mortgageLoan: {
        findMany: jest.fn(),
        count: jest.fn(),
        findFirst: jest.fn(),
        update: jest.fn(),
      },
      mortgagePayment: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
      },
      tenant: {
        findUnique: jest.fn(),
      },
    };

    return {
      service: new MortgageService(prisma as unknown as PrismaService),
      prisma,
      tx,
    };
  };

  it('aggregates dashboard totals for active mortgage loans', async () => {
    const { service, prisma } = createService();
    prisma.mortgageLoan.findMany.mockResolvedValue([
      makeLoan({ principalAmount: decimal(100000) }),
      makeLoan({
        id: 'loan-2',
        principalAmount: decimal(50000),
        outstandingPrincipal: decimal(50000),
        totalPayableAmount: decimal(50000),
      }),
    ]);
    prisma.mortgageLoan.count.mockResolvedValue(1);
    prisma.mortgagePayment.findMany.mockResolvedValue([
      { amount: decimal(2000) },
      { amount: decimal(1500) },
    ]);

    await expect(service.getDashboard('tenant-1')).resolves.toEqual({
      activeLoans: 2,
      closedLoans: 1,
      totalLoanAmount: 150000,
      outstandingPrincipal: 150000,
      // Cycles run date-to-date: loans opened TODAY have not completed their
      // first day yet, so no interest is charged until tomorrow.
      pendingInterest: 0,
      overdueLoans: 0,
      todaysCollections: 3500,
    });
    // Default period is "today" — the collections query is date-bounded.
    expect(
      prisma.mortgagePayment.findMany.mock.calls[0][0].where.paymentDate,
    ).toEqual(expect.objectContaining({ gte: expect.any(Date) }));
  });

  it('sums collections across the whole history for period=all', async () => {
    const { service, prisma } = createService();
    prisma.mortgageLoan.findMany.mockResolvedValue([]);
    prisma.mortgageLoan.count.mockResolvedValue(0);
    prisma.mortgagePayment.findMany.mockResolvedValue([
      { amount: decimal(2000) },
      { amount: decimal(1500) },
    ]);

    const result = await service.getDashboard('tenant-1', { period: 'all' });
    expect(result.todaysCollections).toBe(3500);
    // No date filter for all-time.
    expect(
      prisma.mortgagePayment.findMany.mock.calls[0][0].where.paymentDate,
    ).toBeUndefined();
  });

  it('filters and maps mortgage loan search results', async () => {
    const { service, prisma } = createService();
    prisma.mortgageLoan.findMany.mockResolvedValue([makeLoan()]);

    const result = await service.findAll('tenant-1', {
      status: 'active',
      search: ' Priya ',
    });

    expect(prisma.mortgageLoan.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          tenantId: 'tenant-1',
          status: 'active',
          OR: expect.arrayContaining([
            { loanNumber: { contains: 'Priya', mode: 'insensitive' } },
            { customerName: { contains: 'Priya', mode: 'insensitive' } },
            { customerPhone: { contains: 'Priya' } },
          ]),
        }),
      }),
    );
    expect(result).toHaveLength(1);
    expect(result[0].customerName).toBe('Priya Shah');
  });

  it('throws when a mortgage loan cannot be found', async () => {
    const { service, prisma } = createService();
    prisma.mortgageLoan.findFirst.mockResolvedValue(null);

    await expect(service.findOne('tenant-1', 'missing-loan')).rejects.toThrow(
      NotFoundException,
    );
  });

  it('creates a loan with a new customer, ornaments, and calculated totals', async () => {
    const { service, tx } = createService();
    tx.customer.findFirst.mockResolvedValue(null);
    tx.customer.create.mockResolvedValue({
      id: 'customer-1',
      name: 'Priya Shah',
      phone: '+919111222333',
      address: 'Mumbai',
      aadharNumber: '1234 5678 9012',
      panNumber: 'ABCDE1234F',
    });
    tx.mortgageLoan.count.mockResolvedValue(0);
    tx.mortgageLoan.create.mockImplementation(({ data }) =>
      Promise.resolve(
        makeLoan({
          loanNumber: data.loanNumber,
          principalAmount: data.principalAmount,
          interestRateMonthly: data.interestRateMonthly,
          monthlyInterestAmount: data.monthlyInterestAmount,
          loanDate: data.loanDate,
          dueDate: data.dueDate,
          customerId: data.customerId,
          customerName: data.customerName,
          customerPhone: data.customerPhone,
          customerAddress: data.customerAddress,
          aadhaarNumber: data.aadhaarNumber,
          panNumber: data.panNumber,
          photoIdUrl: data.photoIdUrl,
          customerPhotoUrl: data.customerPhotoUrl,
          notes: data.notes,
          ornaments: data.ornaments.create.map((ornament, index) => ({
            id: `ornament-${index + 1}`,
            loanId: 'loan-1',
            photos: [],
            createdAt: todayUtc(),
            ...ornament,
          })),
        }),
      ),
    );

    const loanDate = todayUtc();
    const result = await service.createLoan('tenant-1', 'user-1', {
      customerName: 'Priya Shah',
      customerPhone: '+919111222333',
      customerAddress: 'Mumbai',
      aadhaarNumber: '1234 5678 9012',
      panNumber: 'ABCDE1234F',
      photoIdUrl: 'data:image/jpeg;base64,cGhvdG8taWQ=',
      customerPhotoUrl: 'data:image/jpeg;base64,Y3VzdG9tZXI=',
      principalAmount: 100000,
      interestRateMonthly: 2,
      loanDate,
      notes: 'First loan',
      ornaments: [
        {
          ornamentType: 'Bangles',
          purity: '22K',
          grossWeight: 42.5,
          netWeight: 40,
          estimatedValue: 240000,
          description: 'Pair of bangles',
        },
      ],
    });

    const expectedYear = new Date().getFullYear();
    expect(result.loanNumber).toBe(`ML-${expectedYear}-0001`);
    expect(result.customerName).toBe('Priya Shah');
    expect(result.photoIdUrl).toBe('data:image/jpeg;base64,cGhvdG8taWQ=');
    expect(result.customerPhotoUrl).toBe('data:image/jpeg;base64,Y3VzdG9tZXI=');
    expect(result.monthlyInterestAmount).toBe(2000);
    expect(result.outstandingPrincipal).toBe(100000);
    expect(result.ornaments).toEqual([
      expect.objectContaining({
        ornamentType: 'Bangles',
        purity: '22K',
        grossWeight: 42.5,
        netWeight: 40,
        estimatedValue: 240000,
      }),
    ]);
    expect(tx.customer.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ name: 'Priya Shah' }),
      }),
    );
    expect(tx.mortgageLoan.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          loanNumber: `ML-${expectedYear}-0001`,
          createdBy: 'user-1',
          photoIdUrl: 'data:image/jpeg;base64,cGhvdG8taWQ=',
          customerPhotoUrl: 'data:image/jpeg;base64,Y3VzdG9tZXI=',
        }),
      }),
    );
  });

  it('rejects a phone that belongs to a different customer', async () => {
    const { service, tx } = createService();
    tx.customer.findFirst.mockResolvedValue({
      id: 'customer-9',
      name: 'Sunita Deshpande',
      phone: '+919111222333',
    });

    await expect(
      service.createLoan('tenant-1', 'user-1', {
        customerName: 'Priya Shah',
        customerPhone: '+919111222333',
        principalAmount: 50000,
        interestRateMonthly: 2,
        ornaments: [
          {
            ornamentType: 'Chain',
            purity: '22K',
            grossWeight: 10,
            netWeight: 9.5,
          },
        ],
      }),
    ).rejects.toThrow('already belongs to "Sunita Deshpande"');
    expect(tx.customer.create).not.toHaveBeenCalled();
    expect(tx.mortgageLoan.create).not.toHaveBeenCalled();
  });

  it('reuses the customer when the phone and name both match', async () => {
    const { service, tx } = createService();
    tx.customer.findFirst.mockResolvedValue({
      id: 'customer-1',
      name: 'Priya Shah',
      phone: '+919111222333',
      address: 'Mumbai',
      aadharNumber: null,
      panNumber: null,
    });
    tx.mortgageLoan.count.mockResolvedValue(0);
    tx.mortgageLoan.create.mockImplementation(({ data }) =>
      Promise.resolve(makeLoan({ customerId: data.customerId })),
    );

    // Case/whitespace differences still count as the same customer.
    await service.createLoan('tenant-1', 'user-1', {
      customerName: '  priya shah ',
      customerPhone: '+919111222333',
      principalAmount: 50000,
      interestRateMonthly: 2,
      ornaments: [
        {
          ornamentType: 'Chain',
          purity: '22K',
          grossWeight: 10,
          netWeight: 9.5,
        },
      ],
    });

    expect(tx.customer.create).not.toHaveBeenCalled();
    expect(tx.mortgageLoan.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ customerId: 'customer-1' }),
      }),
    );
  });

  it('generates a PDF payload for mortgage payment receipts', async () => {
    const { service, prisma } = createService();
    const paymentDate = todayUtc();
    prisma.mortgagePayment.findFirst.mockResolvedValue({
      id: 'payment-1',
      tenantId: 'tenant-1',
      loanId: 'loan-1',
      amount: decimal(2000),
      paymentType: 'interest',
      paymentMode: 'cash',
      paymentDate,
      receiptNumber: `MR-${new Date().getFullYear()}-0001`,
      referenceNumber: 'CASH-1',
      notes: 'Interest received',
      collectedBy: 'user-1',
      createdAt: paymentDate,
      loan: makeLoan({
        loanDate: paymentDate,
        dueDate: new Date(
          Date.UTC(
            paymentDate.getUTCFullYear(),
            paymentDate.getUTCMonth() + 1,
            paymentDate.getUTCDate(),
          ),
        ),
        ornaments: [
          {
            id: 'ornament-1',
            loanId: 'loan-1',
            ornamentType: 'Bangles',
            purity: '22K',
            grossWeight: decimal(42.5),
            netWeight: decimal(40),
            estimatedValue: decimal(240000),
            description: null,
            photos: [],
            createdAt: paymentDate,
          },
        ],
      }),
    });
    prisma.tenant.findUnique.mockResolvedValue({
      shopName: 'SwarnaLekh',
    });

    const result = await service.getPaymentReceiptPdf(
      'tenant-1',
      'loan-1',
      'payment-1',
    );

    expect(prisma.mortgagePayment.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'payment-1', tenantId: 'tenant-1', loanId: 'loan-1' },
      }),
    );
    expect(result.fileName).toBe(`MR-${new Date().getFullYear()}-0001.pdf`);
    expect(Buffer.from(result.base64, 'base64').toString('utf8')).toContain(
      '%PDF-1.4',
    );
  });

  it('records interest payments with generated receipt numbers and updated totals', async () => {
    const { service, tx } = createService();
    const paymentDate = todayUtc();
    tx.mortgageLoan.findFirst.mockResolvedValue(
      makeLoan({ loanDate: paymentDate }),
    );
    tx.mortgagePayment.count.mockResolvedValue(0);
    tx.mortgagePayment.create.mockResolvedValue({ id: 'payment-1' });
    tx.mortgageLoan.update.mockImplementation(({ data }) =>
      Promise.resolve(
        makeLoan({
          loanDate: paymentDate,
          totalInterestPaid: data.totalInterestPaid,
          totalPrincipalPaid: data.totalPrincipalPaid,
          pendingInterestAmount: data.pendingInterestAmount,
          outstandingPrincipal: data.outstandingPrincipal,
          totalPayableAmount: data.totalPayableAmount,
          payments: [
            {
              id: 'payment-1',
              amount: decimal(2000),
              paymentType: 'interest',
              paymentMode: 'cash',
              paymentDate,
              receiptNumber: `MR-${new Date().getFullYear()}-0001`,
              referenceNumber: null,
              notes: null,
              collectedBy: 'user-1',
              createdAt: paymentDate,
            },
          ],
        }),
      ),
    );

    const result = await service.collectPayment(
      'tenant-1',
      'user-1',
      'loan-1',
      {
        amount: 2000,
        paymentType: 'interest',
        paymentMode: 'cash',
        paymentDate,
      },
    );

    expect(tx.mortgagePayment.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          amount: decimal(2000),
          paymentType: 'interest',
          receiptNumber: `MR-${new Date().getFullYear()}-0001`,
          collectedBy: 'user-1',
        }),
      }),
    );
    expect(tx.mortgageLoan.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          totalInterestPaid: decimal(2000),
          totalPrincipalPaid: decimal(0),
        }),
      }),
    );
    expect(result.payments[0].receiptNumber).toBe(
      `MR-${new Date().getFullYear()}-0001`,
    );
  });

  it('rejects principal payments above outstanding principal', async () => {
    const { service, tx } = createService();
    tx.mortgageLoan.findFirst.mockResolvedValue(
      makeLoan({
        totalPrincipalPaid: decimal(90000),
        outstandingPrincipal: decimal(10000),
        totalPayableAmount: decimal(10000),
      }),
    );

    await expect(
      service.collectPayment('tenant-1', 'user-1', 'loan-1', {
        amount: 20000,
        paymentType: 'principal',
      }),
    ).rejects.toThrow(BadRequestException);
    expect(tx.mortgagePayment.create).not.toHaveBeenCalled();
  });

  it('corrects a payment amount and type, reverting the old effect', async () => {
    const { service, tx } = createService();
    // Loan currently reflects a 2000 interest payment.
    tx.mortgageLoan.findFirst.mockResolvedValue(
      makeLoan({ totalInterestPaid: decimal(2000) }),
    );
    tx.mortgagePayment.findFirst.mockResolvedValue({
      id: 'payment-1',
      amount: decimal(2000),
      paymentType: 'interest',
      notes: null,
    });
    tx.mortgagePayment.update.mockResolvedValue({ id: 'payment-1' });
    tx.mortgageLoan.update.mockImplementation(({ data }) =>
      Promise.resolve(
        makeLoan({
          totalInterestPaid: data.totalInterestPaid,
          totalPrincipalPaid: data.totalPrincipalPaid,
        }),
      ),
    );

    // Correct: it was actually a 5000 principal payment.
    await service.updatePayment('tenant-1', 'loan-1', 'payment-1', {
      amount: 5000,
      paymentType: 'principal',
    });

    expect(tx.mortgagePayment.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          amount: decimal(5000),
          paymentType: 'principal',
        }),
      }),
    );
    // Old 2000 interest reverted (2000-2000=0); new 5000 principal applied.
    expect(tx.mortgageLoan.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          totalInterestPaid: decimal(0),
          totalPrincipalPaid: decimal(5000),
        }),
      }),
    );
  });

  it('refuses to edit closure payments or unknown payments', async () => {
    const { service, tx } = createService();
    tx.mortgageLoan.findFirst.mockResolvedValue(makeLoan());
    tx.mortgagePayment.findFirst.mockResolvedValueOnce({
      id: 'payment-1',
      amount: decimal(100000),
      paymentType: 'closure',
      notes: null,
    });
    await expect(
      service.updatePayment('tenant-1', 'loan-1', 'payment-1', {
        amount: 90000,
      }),
    ).rejects.toThrow(BadRequestException);

    tx.mortgagePayment.findFirst.mockResolvedValueOnce(null);
    await expect(
      service.updatePayment('tenant-1', 'loan-1', 'missing', { amount: 10 }),
    ).rejects.toThrow(NotFoundException);
    expect(tx.mortgagePayment.update).not.toHaveBeenCalled();
  });

  it('rejects a correction that would exceed the loan principal', async () => {
    const { service, tx } = createService();
    tx.mortgageLoan.findFirst.mockResolvedValue(
      makeLoan({ totalPrincipalPaid: decimal(95000) }),
    );
    tx.mortgagePayment.findFirst.mockResolvedValue({
      id: 'payment-1',
      amount: decimal(1000),
      paymentType: 'principal',
      notes: null,
    });

    await expect(
      service.updatePayment('tenant-1', 'loan-1', 'payment-1', {
        amount: 20000,
      }),
    ).rejects.toThrow(BadRequestException);
    expect(tx.mortgagePayment.update).not.toHaveBeenCalled();
  });

  it('requires full settlement before closing a mortgage loan', async () => {
    const { service, tx } = createService();
    tx.mortgageLoan.findFirst.mockResolvedValue(
      makeLoan({
        loanDate: new Date('2026-01-10T00:00:00.000Z'),
        dueDate: new Date('2026-02-10T00:00:00.000Z'),
      }),
    );

    await expect(
      service.closeLoan('tenant-1', 'user-1', 'loan-1', {
        amountPaid: 100000,
        closureDate: new Date('2026-03-10T00:00:00.000Z'),
      }),
    ).rejects.toThrow(BadRequestException);
    expect(tx.mortgagePayment.create).not.toHaveBeenCalled();
  });

  it('closes fully settled mortgage loans and records the closure payment', async () => {
    const { service, tx } = createService();
    const closureDate = new Date('2026-06-10T00:00:00.000Z');
    tx.mortgageLoan.findFirst.mockResolvedValue(
      makeLoan({
        loanDate: closureDate,
        dueDate: new Date('2026-07-10T00:00:00.000Z'),
      }),
    );
    tx.mortgagePayment.count.mockResolvedValue(1);
    tx.mortgagePayment.create.mockResolvedValue({ id: 'payment-2' });
    tx.mortgageLoan.update.mockImplementation(({ data }) =>
      Promise.resolve(
        makeLoan({
          status: data.status,
          closedAt: data.closedAt,
          closedBy: data.closedBy,
          totalInterestPaid: data.totalInterestPaid,
          totalPrincipalPaid: data.totalPrincipalPaid,
          pendingInterestAmount: data.pendingInterestAmount,
          outstandingPrincipal: data.outstandingPrincipal,
          totalPayableAmount: data.totalPayableAmount,
          notes: data.notes,
        }),
      ),
    );

    const result = await service.closeLoan('tenant-1', 'user-1', 'loan-1', {
      amountPaid: 100000,
      paymentMode: 'cash',
      closureDate,
      notes: 'Closed after full settlement',
    });

    expect(tx.mortgagePayment.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          amount: decimal(100000),
          paymentType: 'closure',
          receiptNumber: `MR-${new Date().getFullYear()}-0002`,
        }),
      }),
    );
    expect(result.status).toBe('closed');
    expect(result.outstandingPrincipal).toBe(0);
    expect(result.totalPayableAmount).toBe(0);
  });

  it('records a top-up and grows the outstanding principal', async () => {
    const { service, tx } = createService();
    const loanDate = new Date('2026-01-10T00:00:00.000Z');
    tx.mortgageLoan.findFirst.mockResolvedValue(
      makeLoan({
        loanDate,
        principalAmount: decimal(100000),
        outstandingPrincipal: decimal(100000),
      }),
    );
    tx.mortgageTopup.create.mockResolvedValue({ id: 'topup-1' });
    tx.mortgageLoan.update.mockImplementation(({ data }) =>
      Promise.resolve(
        makeLoan({
          outstandingPrincipal: data.outstandingPrincipal,
          totalPayableAmount: data.totalPayableAmount,
          topups: [{ amount: decimal(50000), topupDate: new Date() }],
        }),
      ),
    );

    const result = await service.topUpLoan('tenant-1', 'user-1', 'loan-1', {
      amount: 50000,
      notes: 'extra advance',
    });

    expect(tx.mortgageTopup.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          loanId: 'loan-1',
          amount: decimal(50000),
        }),
      }),
    );
    // Outstanding principal grows by the top-up.
    expect(result.outstandingPrincipal).toBe(150000);
    expect(result.totalTopups).toBe(50000);
  });

  it('rejects a non-positive top-up', async () => {
    const { service, tx } = createService();
    tx.mortgageLoan.findFirst.mockResolvedValue(makeLoan());

    await expect(
      service.topUpLoan('tenant-1', 'user-1', 'loan-1', { amount: 0 }),
    ).rejects.toThrow('greater than zero');
    expect(tx.mortgageTopup.create).not.toHaveBeenCalled();
  });

  it('reopens a closed loan, dropping the closure and rebuilding real totals', async () => {
    const { service, tx } = createService();
    tx.mortgageLoan.findFirst.mockResolvedValue(
      makeLoan({
        status: 'closed',
        closedAt: new Date('2026-06-10T00:00:00.000Z'),
        closedBy: 'user-1',
        // Close had forced these to "fully paid".
        totalInterestPaid: decimal(2000),
        totalPrincipalPaid: decimal(100000),
        pendingInterestAmount: decimal(0),
        outstandingPrincipal: decimal(0),
        totalPayableAmount: decimal(0),
        payments: [
          { id: 'p-1', amount: decimal(2000), paymentType: 'interest' },
          { id: 'p-2', amount: decimal(100000), paymentType: 'closure' },
        ],
      }),
    );
    tx.mortgagePayment.deleteMany.mockResolvedValue({ count: 1 });
    tx.mortgageLoan.update.mockImplementation(({ data }) =>
      Promise.resolve(
        makeLoan({
          status: data.status,
          closedAt: data.closedAt,
          closedBy: data.closedBy,
          totalInterestPaid: data.totalInterestPaid,
          totalPrincipalPaid: data.totalPrincipalPaid,
          pendingInterestAmount: data.pendingInterestAmount,
          outstandingPrincipal: data.outstandingPrincipal,
          totalPayableAmount: data.totalPayableAmount,
        }),
      ),
    );

    const result = await service.reopenLoan('tenant-1', 'loan-1', {
      notes: 'fix a wrong collection',
    });

    // The synthetic closure payment is removed.
    expect(tx.mortgagePayment.deleteMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ paymentType: 'closure' }),
      }),
    );
    // Real paid totals rebuilt from surviving payments: interest 2000, no
    // principal (close had inflated principal to the full loan).
    expect(tx.mortgageLoan.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          status: 'active',
          closedAt: null,
          closedBy: null,
          totalInterestPaid: decimal(2000),
          totalPrincipalPaid: decimal(0),
          outstandingPrincipal: decimal(100000),
        }),
      }),
    );
    expect(result.status).toBe('active');
  });

  it('refuses to reopen a loan that is not closed', async () => {
    const { service, tx } = createService();
    tx.mortgageLoan.findFirst.mockResolvedValue(makeLoan({ status: 'active' }));

    await expect(service.reopenLoan('tenant-1', 'loan-1', {})).rejects.toThrow(
      'Only a closed loan can be reopened',
    );
    expect(tx.mortgagePayment.deleteMany).not.toHaveBeenCalled();
  });

  it('soft deletes mortgage loans after confirming tenant ownership', async () => {
    const { service, prisma } = createService();
    prisma.mortgageLoan.findFirst.mockResolvedValue(makeLoan());
    prisma.mortgageLoan.update.mockResolvedValue(
      makeLoan({ deletedAt: new Date() }),
    );

    await service.remove('tenant-1', 'loan-1');

    expect(prisma.mortgageLoan.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'loan-1', tenantId: 'tenant-1', deletedAt: null },
      }),
    );
    expect(prisma.mortgageLoan.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'loan-1' },
        data: { deletedAt: expect.any(Date) },
      }),
    );
  });
});
