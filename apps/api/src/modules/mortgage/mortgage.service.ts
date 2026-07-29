import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import {
  addLoanMonths,
  calculateMortgageMonthlyInterest,
  calculateMortgagePayable,
  type TopupMode,
} from '@swarnbook/business-logic';
import { PrismaService } from '../../prisma/prisma.service.js';
import { resolveDateRange } from '../../common/date-range.util.js';
import {
  CloseMortgageLoanDto,
  ReopenMortgageLoanDto,
  CollectMortgagePaymentDto,
  CreateMortgageLoanDto,
  MortgageDashboardQueryDto,
  TopUpMortgageLoanDto,
  UpdateMortgageLoanDto,
  UpdateMortgagePaymentDto,
} from './mortgage.dto.js';

@Injectable()
export class MortgageService {
  private readonly loanInclude = {
    customer: {
      select: {
        id: true,
        name: true,
        phone: true,
        address: true,
      },
    },
    ornaments: {
      orderBy: { createdAt: 'asc' as const },
    },
    payments: {
      orderBy: [
        { paymentDate: 'desc' as const },
        { createdAt: 'desc' as const },
      ],
    },
    topups: {
      orderBy: { topupDate: 'asc' as const },
    },
    creator: {
      select: { id: true, name: true },
    },
    closer: {
      select: { id: true, name: true },
    },
  };

  constructor(private readonly prisma: PrismaService) {}

  async getDashboard(tenantId: string, query: MortgageDashboardQueryDto = {}) {
    // Collections respect the selected period (default: today).
    const range = resolveDateRange(query.period, {
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      defaultPeriod: 'today',
    });

    const [activeLoans, closedLoans, collectionPayments] = await Promise.all([
      this.prisma.mortgageLoan.findMany({
        where: { tenantId, status: 'active', deletedAt: null },
        // Payment + top-up history feed cycle-wise interest accrual.
        include: {
          payments: {
            select: { amount: true, paymentType: true, paymentDate: true },
          },
          topups: { select: { amount: true, topupDate: true } },
        },
      }),
      this.prisma.mortgageLoan.count({
        where: { tenantId, status: 'closed', deletedAt: null },
      }),
      this.prisma.mortgagePayment.findMany({
        where: {
          tenantId,
          ...(range ? { paymentDate: range } : {}),
        },
        select: { amount: true },
      }),
    ]);

    // Ongoing figures use the default "separate" policy; the merge/separate
    // choice for a top-up loan is made at close time.
    const activeSnapshots = activeLoans.map((loan) =>
      this.calculateLoanSnapshot(loan, new Date()),
    );
    const pendingInterest = activeSnapshots.reduce(
      (sum, snapshot) => sum + snapshot.pendingInterestAmount,
      0,
    );
    const outstandingPrincipal = activeSnapshots.reduce(
      (sum, snapshot) => sum + snapshot.outstandingPrincipal,
      0,
    );
    const totalLoanAmount = activeLoans.reduce(
      (sum, loan) => sum + this.toNumber(loan.principalAmount),
      0,
    );
    const overdueLoans = activeSnapshots.filter(
      (snapshot) => this.daysOverdue(snapshot.nextDueDate, new Date()) > 0,
    ).length;
    const todaysCollections = collectionPayments.reduce(
      (sum, payment) => sum + this.toNumber(payment.amount),
      0,
    );

    return {
      activeLoans: activeLoans.length,
      closedLoans,
      totalLoanAmount: this.round2(totalLoanAmount),
      outstandingPrincipal: this.round2(outstandingPrincipal),
      pendingInterest: this.round2(pendingInterest),
      overdueLoans,
      todaysCollections: this.round2(todaysCollections),
    };
  }

  async findAll(
    tenantId: string,
    filters?: { status?: string; search?: string },
  ) {
    const search = filters?.search?.trim();
    const loans = await this.prisma.mortgageLoan.findMany({
      where: {
        tenantId,
        deletedAt: null,
        ...(filters?.status ? { status: filters.status } : {}),
        ...(search
          ? {
              OR: [
                { loanNumber: { contains: search, mode: 'insensitive' } },
                { customerName: { contains: search, mode: 'insensitive' } },
                { customerPhone: { contains: search } },
              ],
            }
          : {}),
      },
      include: this.loanInclude,
      orderBy: { createdAt: 'desc' },
    });

    return loans.map((loan) => this.toLoanResponse(loan));
  }

  async findOne(tenantId: string, id: string) {
    const loan = await this.prisma.mortgageLoan.findFirst({
      where: { id, tenantId, deletedAt: null },
      include: this.loanInclude,
    });

    if (!loan) {
      throw new NotFoundException('Mortgage loan not found');
    }

    return this.toLoanResponse(loan);
  }

  async createLoan(
    tenantId: string,
    userId: string,
    dto: CreateMortgageLoanDto,
  ) {
    this.validateOrnaments(dto);

    return this.prisma.$transaction(async (tx) => {
      const customerSnapshot = await this.resolveCustomerSnapshot(
        tx,
        tenantId,
        dto,
      );
      const loanDate = dto.loanDate ?? new Date();
      const dueDate = dto.dueDate ?? addLoanMonths(loanDate, 1);
      const principalAmount = this.round2(dto.principalAmount);
      const interestRateMonthly = this.round2(dto.interestRateMonthly);
      const monthlyInterestAmount = calculateMortgageMonthlyInterest(
        principalAmount,
        interestRateMonthly,
      );
      const loanNumber = await this.generateLoanNumber(tx, tenantId);
      const snapshot = calculateMortgagePayable({
        principalAmount,
        interestRateMonthly,
        loanDate,
        asOfDate: loanDate,
      });

      const loan = await tx.mortgageLoan.create({
        data: {
          tenantId,
          loanNumber,
          customerId: customerSnapshot.customerId,
          customerName: customerSnapshot.customerName,
          customerPhone: customerSnapshot.customerPhone,
          customerAddress: customerSnapshot.customerAddress,
          aadhaarNumber: customerSnapshot.aadhaarNumber,
          panNumber: customerSnapshot.panNumber,
          photoIdUrl: dto.photoIdUrl,
          customerPhotoUrl: dto.customerPhotoUrl,
          principalAmount: new Prisma.Decimal(principalAmount),
          interestRateMonthly: new Prisma.Decimal(interestRateMonthly),
          monthlyInterestAmount: new Prisma.Decimal(monthlyInterestAmount),
          loanDate,
          dueDate,
          pendingInterestAmount: new Prisma.Decimal(
            snapshot.pendingInterestAmount,
          ),
          outstandingPrincipal: new Prisma.Decimal(
            snapshot.outstandingPrincipal,
          ),
          totalPayableAmount: new Prisma.Decimal(snapshot.totalPayableAmount),
          notes: dto.notes,
          createdBy: userId,
          ornaments: {
            create: dto.ornaments.map((ornament) => ({
              ornamentType: ornament.ornamentType,
              purity: ornament.purity,
              grossWeight: new Prisma.Decimal(ornament.grossWeight),
              netWeight: new Prisma.Decimal(ornament.netWeight),
              estimatedValue:
                ornament.estimatedValue == null
                  ? undefined
                  : new Prisma.Decimal(ornament.estimatedValue),
              description: ornament.description,
            })),
          },
        },
        include: this.loanInclude,
      });

      return this.toLoanResponse(loan);
    });
  }

  async collectPayment(
    tenantId: string,
    userId: string,
    id: string,
    dto: CollectMortgagePaymentDto,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const loan = await this.findActiveLoanForUpdate(tx, tenantId, id);
      const paymentType = dto.paymentType ?? 'interest';
      const paymentDate = dto.paymentDate ?? new Date();
      const amount = this.round2(dto.amount);
      const currentSnapshot = this.calculateLoanSnapshot(loan, paymentDate);
      let totalInterestPaid = this.toNumber(loan.totalInterestPaid);
      let totalPrincipalPaid = this.toNumber(loan.totalPrincipalPaid);

      if (paymentType === 'principal') {
        if (amount > currentSnapshot.outstandingPrincipal) {
          throw new BadRequestException(
            'Principal payment cannot exceed outstanding principal',
          );
        }
        totalPrincipalPaid = this.round2(totalPrincipalPaid + amount);
      } else {
        totalInterestPaid = this.round2(totalInterestPaid + amount);
      }

      await tx.mortgagePayment.create({
        data: {
          tenantId,
          loanId: loan.id,
          amount: new Prisma.Decimal(amount),
          paymentType,
          paymentMode: dto.paymentMode,
          paymentDate,
          receiptNumber: await this.generateReceiptNumber(tx, tenantId),
          referenceNumber: dto.referenceNumber,
          notes: dto.notes,
          collectedBy: userId,
        },
      });

      const updatedSnapshot = calculateMortgagePayable({
        principalAmount: this.toNumber(loan.principalAmount),
        interestRateMonthly: this.toNumber(loan.interestRateMonthly),
        loanDate: loan.loanDate,
        asOfDate: new Date(),
        interestPaid: totalInterestPaid,
        principalPaid: totalPrincipalPaid,
        principalAdditions: this.principalAdditionsOf(loan.topups),
        // Include the payment created above — it's not in loan.payments yet.
        principalPayments: [
          ...this.principalPaymentsOf(loan.payments),
          ...(paymentType === 'principal'
            ? [{ amount, date: paymentDate }]
            : []),
        ],
      });

      const updated = await tx.mortgageLoan.update({
        where: { id: loan.id },
        data: {
          totalInterestPaid: new Prisma.Decimal(totalInterestPaid),
          totalPrincipalPaid: new Prisma.Decimal(totalPrincipalPaid),
          pendingInterestAmount: new Prisma.Decimal(
            updatedSnapshot.pendingInterestAmount,
          ),
          outstandingPrincipal: new Prisma.Decimal(
            updatedSnapshot.outstandingPrincipal,
          ),
          totalPayableAmount: new Prisma.Decimal(
            updatedSnapshot.totalPayableAmount,
          ),
        },
        include: this.loanInclude,
      });

      return this.toLoanResponse(updated);
    });
  }

  /**
   * Add a principal top-up to an active loan. How the top-up accrues interest
   * depends on the shop's global policy: "merge" (from the original loan date)
   * or "separate" (from the top-up's own date). The loan snapshot is refreshed
   * to reflect the larger outstanding principal.
   */
  async topUpLoan(
    tenantId: string,
    userId: string,
    id: string,
    dto: TopUpMortgageLoanDto,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const loan = await this.findActiveLoanForUpdate(tx, tenantId, id);
      const amount = this.round2(dto.amount);
      if (amount <= 0) {
        throw new BadRequestException(
          'Top-up amount must be greater than zero',
        );
      }
      const topupDate = dto.topupDate ?? new Date();

      await tx.mortgageTopup.create({
        data: {
          tenantId,
          loanId: loan.id,
          amount: new Prisma.Decimal(amount),
          topupDate,
          notes: dto.notes,
          createdBy: userId,
        },
      });

      const snapshot = calculateMortgagePayable({
        principalAmount: this.toNumber(loan.principalAmount),
        interestRateMonthly: this.toNumber(loan.interestRateMonthly),
        loanDate: loan.loanDate,
        asOfDate: new Date(),
        interestPaid: this.toNumber(loan.totalInterestPaid),
        principalPaid: this.toNumber(loan.totalPrincipalPaid),
        principalPayments: this.principalPaymentsOf(loan.payments),
        // Include the top-up created above — it's not in loan.topups yet.
        principalAdditions: [
          ...this.principalAdditionsOf(loan.topups),
          { amount, date: topupDate },
        ],
      });

      const updated = await tx.mortgageLoan.update({
        where: { id: loan.id },
        data: {
          monthlyInterestAmount: new Prisma.Decimal(
            snapshot.monthlyInterestAmount,
          ),
          pendingInterestAmount: new Prisma.Decimal(
            snapshot.pendingInterestAmount,
          ),
          outstandingPrincipal: new Prisma.Decimal(
            snapshot.outstandingPrincipal,
          ),
          totalPayableAmount: new Prisma.Decimal(snapshot.totalPayableAmount),
        },
        include: this.loanInclude,
      });

      return this.toLoanResponse(updated);
    });
  }

  /**
   * Correct a recorded payment (wrong amount / wrong type). Reverts the old
   * payment's effect on the loan totals, applies the new values, and refreshes
   * the loan snapshot. Only active loans; closure payments cannot be edited.
   */
  async updatePayment(
    tenantId: string,
    loanId: string,
    paymentId: string,
    dto: UpdateMortgagePaymentDto,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const loan = await this.findActiveLoanForUpdate(tx, tenantId, loanId);
      const payment = await tx.mortgagePayment.findFirst({
        where: { id: paymentId, loanId: loan.id, tenantId },
      });
      if (!payment) {
        throw new NotFoundException('Payment not found');
      }
      if (payment.paymentType === 'closure') {
        throw new BadRequestException(
          'Closure payments cannot be edited. Reopen the loan instead.',
        );
      }

      const oldAmount = this.toNumber(payment.amount);
      const oldType = payment.paymentType ?? 'interest';
      const newAmount = this.round2(dto.amount ?? oldAmount);
      const newType = dto.paymentType ?? oldType;
      if (newAmount <= 0) {
        throw new BadRequestException('Amount must be greater than zero');
      }

      let totalInterestPaid = this.toNumber(loan.totalInterestPaid);
      let totalPrincipalPaid = this.toNumber(loan.totalPrincipalPaid);
      if (oldType === 'principal') {
        totalPrincipalPaid = this.round2(totalPrincipalPaid - oldAmount);
      } else {
        totalInterestPaid = this.round2(totalInterestPaid - oldAmount);
      }
      if (newType === 'principal') {
        totalPrincipalPaid = this.round2(totalPrincipalPaid + newAmount);
      } else {
        totalInterestPaid = this.round2(totalInterestPaid + newAmount);
      }

      if (totalInterestPaid < 0 || totalPrincipalPaid < 0) {
        throw new BadRequestException(
          'This correction would make the paid totals negative',
        );
      }
      const principalCeiling =
        this.toNumber(loan.principalAmount) +
        this.principalAdditionsOf(loan.topups).reduce(
          (sum, a) => sum + a.amount,
          0,
        );
      if (totalPrincipalPaid > principalCeiling + 0.01) {
        throw new BadRequestException(
          'Principal paid cannot exceed the loan amount',
        );
      }

      await tx.mortgagePayment.update({
        where: { id: payment.id },
        data: {
          amount: new Prisma.Decimal(newAmount),
          paymentType: newType,
          ...(dto.notes !== undefined ? { notes: dto.notes } : {}),
        },
      });

      const snapshot = calculateMortgagePayable({
        principalAmount: this.toNumber(loan.principalAmount),
        interestRateMonthly: this.toNumber(loan.interestRateMonthly),
        loanDate: loan.loanDate,
        asOfDate: new Date(),
        interestPaid: totalInterestPaid,
        principalPaid: totalPrincipalPaid,
        principalAdditions: this.principalAdditionsOf(loan.topups),
        // History with the edited payment's corrected amount/type applied.
        principalPayments: this.principalPaymentsOf(
          (loan.payments as any[]).map((p) =>
            p.id === payment.id
              ? { ...p, amount: newAmount, paymentType: newType }
              : p,
          ),
        ),
      });

      const updated = await tx.mortgageLoan.update({
        where: { id: loan.id },
        data: {
          totalInterestPaid: new Prisma.Decimal(totalInterestPaid),
          totalPrincipalPaid: new Prisma.Decimal(totalPrincipalPaid),
          pendingInterestAmount: new Prisma.Decimal(
            snapshot.pendingInterestAmount,
          ),
          outstandingPrincipal: new Prisma.Decimal(
            snapshot.outstandingPrincipal,
          ),
          totalPayableAmount: new Prisma.Decimal(snapshot.totalPayableAmount),
        },
        include: this.loanInclude,
      });

      return this.toLoanResponse(updated);
    });
  }

  async closeLoan(
    tenantId: string,
    userId: string,
    id: string,
    dto: CloseMortgageLoanDto,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const loan = await this.findActiveLoanForUpdate(tx, tenantId, id);
      // The operator chooses how a top-up accrues interest at close time.
      const topupMode: TopupMode =
        dto.topupInterestMode === 'merge' ? 'merge' : 'separate';
      const closureDate = dto.closureDate ?? new Date();
      const snapshot = this.calculateLoanSnapshot(loan, closureDate, topupMode);
      const amountPaid = this.round2(dto.amountPaid);

      if (amountPaid + 0.01 < snapshot.totalPayableAmount) {
        throw new BadRequestException(
          `Full settlement requires at least ${snapshot.totalPayableAmount}`,
        );
      }

      if (amountPaid > 0) {
        await tx.mortgagePayment.create({
          data: {
            tenantId,
            loanId: loan.id,
            amount: new Prisma.Decimal(amountPaid),
            paymentType: 'closure',
            paymentMode: dto.paymentMode,
            paymentDate: closureDate,
            receiptNumber: await this.generateReceiptNumber(tx, tenantId),
            notes: dto.notes,
            collectedBy: userId,
          },
        });
      }

      const updated = await tx.mortgageLoan.update({
        where: { id: loan.id },
        data: {
          status: 'closed',
          closedAt: closureDate,
          closedBy: userId,
          totalInterestPaid: new Prisma.Decimal(
            this.round2(
              this.toNumber(loan.totalInterestPaid) +
                snapshot.pendingInterestAmount,
            ),
          ),
          // Settlement clears the original principal plus any top-ups.
          totalPrincipalPaid: new Prisma.Decimal(
            this.round2(
              this.toNumber(loan.principalAmount) +
                this.principalAdditionsOf(loan.topups).reduce(
                  (sum, a) => sum + a.amount,
                  0,
                ),
            ),
          ),
          pendingInterestAmount: new Prisma.Decimal(0),
          outstandingPrincipal: new Prisma.Decimal(0),
          totalPayableAmount: new Prisma.Decimal(0),
          notes: dto.notes ?? loan.notes,
        },
        include: this.loanInclude,
      });

      return this.toLoanResponse(updated);
    });
  }

  /**
   * The loan's transaction ledger: disbursal, top-ups, collections and closure
   * in chronological order — the source for the on-screen ledger and the
   * printable statement.
   */
  async getLedger(tenantId: string, id: string) {
    const loan = await this.prisma.mortgageLoan.findFirst({
      where: { id, tenantId, deletedAt: null },
      include: this.loanInclude,
    });
    if (!loan) throw new NotFoundException('Mortgage loan not found');

    type Event = {
      date: Date;
      type: string;
      amount: number;
      direction: 'debit' | 'credit';
      order: number;
    };
    const events: Event[] = [];
    events.push({
      date: loan.loanDate,
      type: 'loan_created',
      amount: this.toNumber(loan.principalAmount),
      direction: 'debit',
      order: 0,
    });
    for (const t of loan.topups ?? []) {
      events.push({
        date: t.topupDate,
        type: 'topup_added',
        amount: this.toNumber(t.amount),
        direction: 'debit',
        order: 1,
      });
    }
    for (const p of loan.payments ?? []) {
      const isClosure = p.paymentType === 'closure';
      events.push({
        date: p.paymentDate,
        type: isClosure
          ? 'closed'
          : p.paymentType === 'principal'
            ? 'principal_collected'
            : 'interest_collected',
        amount: this.toNumber(p.amount),
        direction: 'credit',
        order: isClosure ? 3 : 2,
      });
    }

    events.sort((a, b) => {
      const d = new Date(a.date).getTime() - new Date(b.date).getTime();
      return d !== 0 ? d : a.order - b.order;
    });

    return {
      loanId: loan.id,
      loanNumber: loan.loanNumber,
      events: events.map((e) => ({
        date: e.date,
        type: e.type,
        amount: this.round2(e.amount),
        direction: e.direction,
      })),
    };
  }

  /**
   * Edit a loan's correctable fields (customer snapshot, interest rate, notes).
   * Principal and loan date are immutable — changing them would rewrite the
   * interest history. A rate change refreshes the snapshot.
   */
  async updateLoan(tenantId: string, id: string, dto: UpdateMortgageLoanDto) {
    return this.prisma.$transaction(async (tx) => {
      const loan = await tx.mortgageLoan.findFirst({
        where: { id, tenantId, deletedAt: null },
        include: this.loanInclude,
      });
      if (!loan) throw new NotFoundException('Mortgage loan not found');

      const interestRateMonthly =
        dto.interestRateMonthly != null
          ? this.round2(dto.interestRateMonthly)
          : this.toNumber(loan.interestRateMonthly);

      const merged = { ...loan, interestRateMonthly };
      const snapshot = this.calculateLoanSnapshot(merged, new Date());

      const updated = await tx.mortgageLoan.update({
        where: { id: loan.id },
        data: {
          ...(dto.customerName !== undefined
            ? { customerName: dto.customerName }
            : {}),
          ...(dto.customerPhone !== undefined
            ? { customerPhone: dto.customerPhone }
            : {}),
          ...(dto.aadhaarNumber !== undefined
            ? { aadhaarNumber: dto.aadhaarNumber }
            : {}),
          ...(dto.panNumber !== undefined ? { panNumber: dto.panNumber } : {}),
          ...(dto.notes !== undefined ? { notes: dto.notes } : {}),
          ...(dto.interestRateMonthly != null
            ? {
                interestRateMonthly: new Prisma.Decimal(interestRateMonthly),
                monthlyInterestAmount: new Prisma.Decimal(
                  snapshot.monthlyInterestAmount,
                ),
                pendingInterestAmount: new Prisma.Decimal(
                  snapshot.pendingInterestAmount,
                ),
                totalPayableAmount: new Prisma.Decimal(
                  snapshot.totalPayableAmount,
                ),
              }
            : {}),
        },
        include: this.loanInclude,
      });

      return this.toLoanResponse(updated);
    });
  }

  /**
   * Figures the Close screen needs to let the operator pick a top-up interest
   * policy: the settlement under BOTH "separate" and "merge", plus the dates
   * and total top-up that explain the difference. `hasTopups` is false when the
   * loan has no top-ups (the screen then shows a plain close).
   */
  async getClosePreview(tenantId: string, id: string, asOf?: Date) {
    const loan = await this.prisma.mortgageLoan.findFirst({
      where: { id, tenantId, deletedAt: null },
      include: this.loanInclude,
    });
    if (!loan) throw new NotFoundException('Mortgage loan not found');
    const asOfDate = asOf ?? new Date();

    const project = (mode: TopupMode) => {
      const s = this.calculateLoanSnapshot(loan, asOfDate, mode);
      return {
        pendingInterest: s.pendingInterestAmount,
        outstandingPrincipal: s.outstandingPrincipal,
        totalPayable: s.totalPayableAmount,
      };
    };

    const topups = (loan.topups ?? []) as Array<{
      amount: unknown;
      topupDate: Date;
    }>;
    const totalTopups = this.round2(
      topups.reduce((sum, t) => sum + this.toNumber(t.amount), 0),
    );

    return {
      loanId: loan.id,
      hasTopups: topups.length > 0,
      loanDate: loan.loanDate,
      firstTopupDate: topups.length > 0 ? topups[0].topupDate : null,
      totalTopups,
      separate: project('separate'),
      merge: project('merge'),
    };
  }

  /**
   * Reopen a closed loan so its Collect/Close entries can be corrected. Closing
   * writes a synthetic settlement (a `closure` payment plus totals forced to
   * "fully paid"); reopening reverses exactly that: it deletes the closure
   * payment(s), rebuilds the real paid totals from the surviving payment rows,
   * flips the loan back to `active`, and recomputes the snapshot as of today.
   * The owner then edits entries via the normal flow and closes again.
   */
  async reopenLoan(tenantId: string, id: string, dto: ReopenMortgageLoanDto) {
    return this.prisma.$transaction(async (tx) => {
      const loan = await tx.mortgageLoan.findFirst({
        where: { id, tenantId, deletedAt: null },
        include: this.loanInclude,
      });
      if (!loan) throw new NotFoundException('Mortgage loan not found');
      if (loan.status !== 'closed') {
        throw new BadRequestException('Only a closed loan can be reopened');
      }

      // Drop the settlement artifact created at close time.
      await tx.mortgagePayment.deleteMany({
        where: { tenantId, loanId: loan.id, paymentType: 'closure' },
      });

      // Rebuild the true paid totals from the payments that actually happened
      // (closure rows excluded) — close had overwritten them with settlement
      // values (principal forced to the full loan, interest bumped by the
      // pending amount).
      const surviving = (loan.payments as any[]).filter(
        (p) => p.paymentType !== 'closure',
      );
      const totalPrincipalPaid = this.round2(
        surviving
          .filter((p) => p.paymentType === 'principal')
          .reduce((sum, p) => sum + this.toNumber(p.amount), 0),
      );
      const totalInterestPaid = this.round2(
        surviving
          .filter(
            (p) => p.paymentType !== 'principal' && p.paymentType !== 'closure',
          )
          .reduce((sum, p) => sum + this.toNumber(p.amount), 0),
      );

      const snapshot = calculateMortgagePayable({
        principalAmount: this.toNumber(loan.principalAmount),
        interestRateMonthly: this.toNumber(loan.interestRateMonthly),
        loanDate: loan.loanDate,
        asOfDate: new Date(),
        interestPaid: totalInterestPaid,
        principalPaid: totalPrincipalPaid,
        principalPayments: this.principalPaymentsOf(surviving),
        principalAdditions: this.principalAdditionsOf(loan.topups),
      });

      const updated = await tx.mortgageLoan.update({
        where: { id: loan.id },
        data: {
          status: 'active',
          closedAt: null,
          closedBy: null,
          totalInterestPaid: new Prisma.Decimal(totalInterestPaid),
          totalPrincipalPaid: new Prisma.Decimal(totalPrincipalPaid),
          pendingInterestAmount: new Prisma.Decimal(
            snapshot.pendingInterestAmount,
          ),
          outstandingPrincipal: new Prisma.Decimal(
            snapshot.outstandingPrincipal,
          ),
          totalPayableAmount: new Prisma.Decimal(snapshot.totalPayableAmount),
          ...(dto.notes !== undefined ? { notes: dto.notes } : {}),
        },
        include: this.loanInclude,
      });

      return this.toLoanResponse(updated);
    });
  }

  async getPaymentReceiptPdf(
    tenantId: string,
    loanId: string,
    paymentId: string,
  ) {
    const payment = await this.prisma.mortgagePayment.findFirst({
      where: { id: paymentId, tenantId, loanId },
      include: {
        loan: {
          include: {
            ornaments: {
              orderBy: { createdAt: 'asc' },
            },
          },
        },
      },
    });

    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantId },
      select: { shopName: true },
    });

    if (!payment || payment.loan.deletedAt) {
      throw new NotFoundException('Mortgage payment receipt not found');
    }

    const shopName = tenant?.shopName ?? 'SwarnaLekh';
    const pdf = this.buildPaymentReceiptPdf(payment, shopName);
    const receiptNumber = payment.receiptNumber ?? payment.id;

    return {
      fileName: `${receiptNumber}.pdf`,
      base64: pdf.toString('base64'),
    };
  }

  async remove(tenantId: string, id: string) {
    await this.findOne(tenantId, id);
    return this.prisma.mortgageLoan.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  private async resolveCustomerSnapshot(
    tx: Prisma.TransactionClient,
    tenantId: string,
    dto: CreateMortgageLoanDto,
  ) {
    if (dto.customerId) {
      const customer = await tx.customer.findFirst({
        where: { id: dto.customerId, tenantId, deletedAt: null },
      });
      if (!customer) throw new NotFoundException('Customer not found');
      return {
        customerId: customer.id,
        customerName: customer.name,
        customerPhone: customer.phone,
        customerAddress: customer.address,
        aadhaarNumber: dto.aadhaarNumber ?? customer.aadharNumber,
        panNumber: dto.panNumber ?? customer.panNumber,
      };
    }

    if (!dto.customerName) {
      throw new BadRequestException('Customer name or ID is required');
    }

    const existingCustomer = dto.customerPhone
      ? await tx.customer.findFirst({
          where: {
            tenantId,
            deletedAt: null,
            phone: dto.customerPhone,
          },
        })
      : null;

    // A phone that belongs to a *different* customer must not silently switch
    // the loan onto the existing record — surface it for verification instead.
    if (
      existingCustomer &&
      existingCustomer.name.trim().toLowerCase() !==
        dto.customerName.trim().toLowerCase()
    ) {
      throw new BadRequestException(
        `This mobile number already belongs to "${existingCustomer.name}". ` +
          'Please verify the customer details.',
      );
    }

    const customer =
      existingCustomer ??
      (await tx.customer.create({
        data: {
          tenantId,
          name: dto.customerName,
          phone: dto.customerPhone,
          address: dto.customerAddress,
          aadharNumber: dto.aadhaarNumber,
          panNumber: dto.panNumber,
        },
      }));

    return {
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      customerAddress: customer.address ?? dto.customerAddress,
      aadhaarNumber: dto.aadhaarNumber ?? customer.aadharNumber,
      panNumber: dto.panNumber ?? customer.panNumber,
    };
  }

  private async findActiveLoanForUpdate(
    tx: Prisma.TransactionClient,
    tenantId: string,
    id: string,
  ) {
    const loan = await tx.mortgageLoan.findFirst({
      where: { id, tenantId, deletedAt: null },
      include: this.loanInclude,
    });

    if (!loan) throw new NotFoundException('Mortgage loan not found');
    if (loan.status !== 'active') {
      throw new BadRequestException('Mortgage loan is not active');
    }
    return loan;
  }

  private async generateLoanNumber(
    tx: Prisma.TransactionClient,
    tenantId: string,
  ) {
    const year = new Date().getFullYear();
    const startOfYear = new Date(year, 0, 1);
    const count = await tx.mortgageLoan.count({
      where: { tenantId, createdAt: { gte: startOfYear } },
    });
    return `ML-${year}-${String(count + 1).padStart(4, '0')}`;
  }

  private async generateReceiptNumber(
    tx: Prisma.TransactionClient,
    tenantId: string,
  ) {
    const year = new Date().getFullYear();
    const startOfYear = new Date(year, 0, 1);
    const count = await tx.mortgagePayment.count({
      where: { tenantId, createdAt: { gte: startOfYear } },
    });
    return `MR-${year}-${String(count + 1).padStart(4, '0')}`;
  }

  private validateOrnaments(dto: CreateMortgageLoanDto) {
    for (const [index, ornament] of dto.ornaments.entries()) {
      if (ornament.netWeight > ornament.grossWeight) {
        throw new BadRequestException(
          `Ornament ${index + 1}: net weight cannot be greater than gross weight`,
        );
      }
    }
  }

  /** Principal-payment history for cycle-wise interest accrual. */
  private principalPaymentsOf(
    payments:
      | Array<{
          amount: unknown;
          paymentType?: string | null;
          paymentDate: Date;
        }>
      | undefined,
  ) {
    return (payments ?? [])
      .filter((p) => p.paymentType === 'principal')
      .map((p) => ({ amount: this.toNumber(p.amount), date: p.paymentDate }));
  }

  /** Top-up history (principal additions) for cycle-wise interest accrual. */
  private principalAdditionsOf(
    topups: Array<{ amount: unknown; topupDate: Date }> | undefined,
  ) {
    return (topups ?? []).map((t) => ({
      amount: this.toNumber(t.amount),
      date: t.topupDate,
    }));
  }

  private calculateLoanSnapshot(
    loan: any,
    asOfDate: Date,
    topupMode: TopupMode = 'separate',
  ) {
    return calculateMortgagePayable({
      principalPayments: this.principalPaymentsOf(loan.payments),
      principalAdditions: this.principalAdditionsOf(loan.topups),
      topupMode,
      principalAmount: this.toNumber(loan.principalAmount),
      interestRateMonthly: this.toNumber(loan.interestRateMonthly),
      loanDate: loan.loanDate,
      asOfDate,
      interestPaid: this.toNumber(loan.totalInterestPaid),
      principalPaid: this.toNumber(loan.totalPrincipalPaid),
    });
  }

  private toLoanResponse(loan: any, topupMode: TopupMode = 'separate') {
    const snapshot = this.calculateLoanSnapshot(loan, new Date(), topupMode);
    const isClosed = loan.status === 'closed';
    const nextDueDate = isClosed ? null : snapshot.nextDueDate;
    const totalTopups = (loan.topups ?? []).reduce(
      (sum: number, t: any) => sum + this.toNumber(t.amount),
      0,
    );

    return {
      id: loan.id,
      tenantId: loan.tenantId,
      loanNumber: loan.loanNumber,
      customerId: loan.customerId,
      customerName: loan.customerName,
      customerPhone: loan.customerPhone,
      customerAddress: loan.customerAddress,
      aadhaarNumber: loan.aadhaarNumber,
      panNumber: loan.panNumber,
      photoIdUrl: loan.photoIdUrl,
      customerPhotoUrl: loan.customerPhotoUrl,
      principalAmount: this.toNumber(loan.principalAmount),
      totalTopups: this.round2(totalTopups),
      interestRateMonthly: this.toNumber(loan.interestRateMonthly),
      monthlyInterestAmount: snapshot.monthlyInterestAmount,
      loanDate: loan.loanDate,
      dueDate: loan.dueDate,
      totalInterestPaid: this.toNumber(loan.totalInterestPaid),
      totalPrincipalPaid: this.toNumber(loan.totalPrincipalPaid),
      pendingInterestAmount: isClosed ? 0 : snapshot.pendingInterestAmount,
      // Months of interest charged so far (started month = full month).
      interestMonths: isClosed ? 0 : snapshot.elapsedMonths,
      outstandingPrincipal: isClosed ? 0 : snapshot.outstandingPrincipal,
      totalPayableAmount: isClosed ? 0 : snapshot.totalPayableAmount,
      nextDueDate,
      daysOverdue: nextDueDate ? this.daysOverdue(nextDueDate, new Date()) : 0,
      status: loan.status,
      notes: loan.notes,
      closedAt: loan.closedAt,
      createdAt: loan.createdAt,
      updatedAt: loan.updatedAt,
      customer: loan.customer,
      creator: loan.creator,
      closer: loan.closer,
      ornaments: (loan.ornaments ?? []).map((ornament: any) => ({
        id: ornament.id,
        ornamentType: ornament.ornamentType,
        purity: ornament.purity,
        grossWeight: this.toNumber(ornament.grossWeight),
        netWeight: this.toNumber(ornament.netWeight),
        estimatedValue:
          ornament.estimatedValue == null
            ? null
            : this.toNumber(ornament.estimatedValue),
        description: ornament.description,
        photos: ornament.photos,
        createdAt: ornament.createdAt,
      })),
      payments: (loan.payments ?? []).map((payment: any) => ({
        id: payment.id,
        paymentDate: payment.paymentDate,
        amount: this.toNumber(payment.amount),
        paymentType: payment.paymentType,
        paymentMode: payment.paymentMode,
        receiptNumber: payment.receiptNumber,
        referenceNumber: payment.referenceNumber,
        notes: payment.notes,
        collectedBy: payment.collectedBy,
        createdAt: payment.createdAt,
      })),
      topups: (loan.topups ?? []).map((topup: any) => ({
        id: topup.id,
        amount: this.toNumber(topup.amount),
        topupDate: topup.topupDate,
        notes: topup.notes,
        createdAt: topup.createdAt,
      })),
    };
  }

  private buildPaymentReceiptPdf(payment: any, shopName: string) {
    const loan = payment.loan;
    const ornaments = loan.ornaments ?? [];
    const lines = [
      `${shopName} Mortgage Payment Receipt`,
      '',
      `Receipt Number: ${payment.receiptNumber ?? '-'}`,
      `Payment Date: ${this.formatDate(payment.paymentDate)}`,
      `Loan Number: ${loan.loanNumber}`,
      `Customer Name: ${loan.customerName}`,
      loan.customerPhone ? `Mobile Number: ${loan.customerPhone}` : '',
      '',
      'Loan Details',
      `Loan Amount: ${this.formatMoney(loan.principalAmount)}`,
      `Interest Rate: ${this.toNumber(loan.interestRateMonthly)}% monthly`,
      `Loan Date: ${this.formatDate(loan.loanDate)}`,
      `Due Date: ${this.formatDate(loan.dueDate)}`,
      '',
      'Payment Details',
      `Payment Type: ${this.readableValue(payment.paymentType)}`,
      `Amount: ${this.formatMoney(payment.amount)}`,
      `Payment Method: ${this.readableValue(payment.paymentMode ?? '-')}`,
      payment.referenceNumber
        ? `Reference Number: ${payment.referenceNumber}`
        : '',
      '',
      'Updated Balance',
      `Pending Balance: ${this.formatMoney(loan.totalPayableAmount)}`,
      `Pending Interest: ${this.formatMoney(loan.pendingInterestAmount)}`,
      `Next Due Date: ${this.formatDate(this.calculateLoanSnapshot(loan, new Date()).nextDueDate)}`,
      '',
      'Pledged Ornament Details',
      ...ornaments.map(
        (ornament: any, index: number) =>
          `${index + 1}. ${ornament.ornamentType} | ${ornament.purity ?? '-'} | Gross ${this.toNumber(ornament.grossWeight).toFixed(3)}g | Net ${this.toNumber(ornament.netWeight).toFixed(3)}g`,
      ),
      '',
      payment.notes ? `Notes: ${payment.notes}` : '',
      `Generated by ${shopName}`,
    ].filter((line) => line.trim().length > 0);

    return this.renderTextPdf(lines);
  }

  private renderTextPdf(lines: string[]) {
    const pageWidth = 595;
    const pageHeight = 842;
    const left = 40;
    const top = 802;
    const lineHeight = 14;
    const maxLines = Math.floor((top - 40) / lineHeight);
    const pages: string[] = [];

    for (let index = 0; index < lines.length; index += maxLines) {
      const pageLines = lines.slice(index, index + maxLines);
      const stream = [
        'BT',
        '/F1 9 Tf',
        `${left} ${top} Td`,
        `${lineHeight} TL`,
        ...pageLines.flatMap((line, lineIndex) => {
          const text = `(${this.escapePdfText(this.truncatePdfLine(line))}) Tj`;
          return lineIndex === 0 ? [text] : ['T*', text];
        }),
        'ET',
      ].join('\n');
      pages.push(stream);
    }

    const objects: string[] = [];
    const addObject = (body: string) => {
      objects.push(body);
      return objects.length;
    };

    const catalogId = addObject('<< /Type /Catalog /Pages 2 0 R >>');
    const pagesId = addObject('');
    const fontId = addObject(
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    );
    const pageIds: number[] = [];

    for (const stream of pages) {
      const contentId = addObject(
        `<< /Length ${Buffer.byteLength(stream, 'utf8')} >>\nstream\n${stream}\nendstream`,
      );
      const pageId = addObject(
        [
          '<< /Type /Page',
          `/Parent ${pagesId} 0 R`,
          `/MediaBox [0 0 ${pageWidth} ${pageHeight}]`,
          `/Resources << /Font << /F1 ${fontId} 0 R >> >>`,
          `/Contents ${contentId} 0 R`,
          '>>',
        ].join(' '),
      );
      pageIds.push(pageId);
    }

    objects[pagesId - 1] =
      `<< /Type /Pages /Kids [${pageIds.map((id) => `${id} 0 R`).join(' ')}] /Count ${pageIds.length} >>`;

    const parts = ['%PDF-1.4\n'];
    const offsets = [0];
    for (let index = 0; index < objects.length; index += 1) {
      offsets.push(Buffer.byteLength(parts.join(''), 'utf8'));
      parts.push(`${index + 1} 0 obj\n${objects[index]}\nendobj\n`);
    }
    const xrefOffset = Buffer.byteLength(parts.join(''), 'utf8');
    parts.push(`xref\n0 ${objects.length + 1}\n`);
    parts.push('0000000000 65535 f \n');
    for (const offset of offsets.slice(1)) {
      parts.push(`${offset.toString().padStart(10, '0')} 00000 n \n`);
    }
    parts.push(
      [
        'trailer',
        `<< /Size ${objects.length + 1} /Root ${catalogId} 0 R >>`,
        'startxref',
        xrefOffset.toString(),
        '%%EOF',
      ].join('\n'),
    );

    return Buffer.from(parts.join(''), 'utf8');
  }

  private escapePdfText(value: string) {
    return value
      .replace(/\\/g, '\\\\')
      .replace(/\(/g, '\\(')
      .replace(/\)/g, '\\)');
  }

  private truncatePdfLine(value: string) {
    return value.length > 110 ? `${value.slice(0, 107)}...` : value;
  }

  private formatDate(value?: Date | string | null) {
    if (!value) return '-';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '-';
    return date.toISOString().slice(0, 10);
  }

  private formatMoney(value: unknown) {
    return `INR ${this.toNumber(value).toFixed(2)}`;
  }

  private readableValue(value: string) {
    return value
      .split('_')
      .filter(Boolean)
      .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
      .join(' ');
  }

  private daysOverdue(dueDate: Date, asOfDate: Date) {
    const due = new Date(dueDate);
    due.setHours(0, 0, 0, 0);
    const asOf = new Date(asOfDate);
    asOf.setHours(0, 0, 0, 0);
    const diff = asOf.getTime() - due.getTime();
    return diff > 0 ? Math.floor(diff / 86_400_000) : 0;
  }

  private toNumber(value: unknown): number {
    if (value == null) return 0;
    if (typeof value === 'number') return value;
    if (typeof value === 'object' && 'toNumber' in value) {
      return (value as { toNumber: () => number }).toNumber();
    }
    const numberValue = Number(value);
    return Number.isFinite(numberValue) ? numberValue : 0;
  }

  private round2(value: number) {
    return Math.round((value + Number.EPSILON) * 100) / 100;
  }
}
