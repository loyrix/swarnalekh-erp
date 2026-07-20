export interface JewelleryTaxBreakdown {
  cgstPercent: number;
  cgstAmount: number;
  sgstPercent: number;
  sgstAmount: number;
  totalTax: number;
}

export interface ItemPriceInput {
  netWeight: number;
  ratePerGram: number;
  makingCharges?: number;
  stoneValue?: number;
  wastagePercent?: number;
}

export interface ItemPriceBreakdown {
  metalValue: number;
  makingCharges: number;
  stoneValue: number;
  wastageValue: number;
  itemTotal: number;
}

export interface InvoiceTotalsInput {
  itemTotals: number[];
  discountAmount?: number;
  oldGoldValue?: number;
  /** Total GST %, split evenly into CGST/SGST. Defaults to 3 (1.5 + 1.5). */
  gstPercent?: number;
}

export interface InvoiceTotalsBreakdown extends JewelleryTaxBreakdown {
  subtotal: number;
  discountAmount: number;
  oldGoldValue: number;
  taxableAmount: number;
  grandTotalRaw: number;
  roundOff: number;
  grandTotal: number;
}

export interface PrincipalPaymentInput {
  amount: number;
  date: Date | string;
}

export interface MortgagePayableInput {
  principalAmount: number;
  interestRateMonthly: number;
  loanDate: Date | string;
  asOfDate?: Date | string;
  interestPaid?: number;
  principalPaid?: number;
  /**
   * Principal-payment history, used to accrue each cycle's interest on the
   * principal outstanding at that cycle's start (a payment reduces interest
   * from the NEXT cycle; the running cycle stays charged). When omitted,
   * accrual falls back to the flat original-principal model.
   */
  principalPayments?: PrincipalPaymentInput[];
}

export interface MortgagePayableBreakdown {
  elapsedMonths: number;
  monthlyInterestAmount: number;
  accruedInterestAmount: number;
  interestPaid: number;
  pendingInterestAmount: number;
  principalPaid: number;
  outstandingPrincipal: number;
  totalPayableAmount: number;
  nextDueDate: Date;
}

const round2 = (value: number): number =>
  Math.round((value + Number.EPSILON) * 100) / 100;

export function calculateJewelleryTax(
  taxableAmount: number,
  totalGstPercent = 3,
): JewelleryTaxBreakdown {
  const safeTaxableAmount = Math.max(0, taxableAmount);
  const half = Math.max(0, totalGstPercent) / 2;
  const cgstPercent = half;
  const sgstPercent = half;
  const cgstAmount = round2((safeTaxableAmount * cgstPercent) / 100);
  const sgstAmount = round2((safeTaxableAmount * sgstPercent) / 100);
  return {
    cgstPercent,
    cgstAmount,
    sgstPercent,
    sgstAmount,
    totalTax: round2(cgstAmount + sgstAmount),
  };
}

export function calculateOldGoldValue(
  weight: number,
  ratePerGram: number,
): number {
  if (weight <= 0 || ratePerGram <= 0) return 0;
  return round2(weight * ratePerGram);
}

export function calculateItemPrice(input: ItemPriceInput): ItemPriceBreakdown {
  const metalValue = round2(input.netWeight * input.ratePerGram);
  const makingCharges = round2(input.makingCharges ?? 0);
  const stoneValue = round2(input.stoneValue ?? 0);
  const wastagePercent = Math.max(0, input.wastagePercent ?? 0);
  const wastageValue = round2((metalValue * wastagePercent) / 100);
  return {
    metalValue,
    makingCharges,
    stoneValue,
    wastageValue,
    itemTotal: round2(metalValue + makingCharges + stoneValue + wastageValue),
  };
}

export function calculateInvoiceTotals(
  input: InvoiceTotalsInput,
): InvoiceTotalsBreakdown {
  const subtotal = round2(
    input.itemTotals.reduce((sum, value) => sum + value, 0),
  );
  const discountAmount = round2(input.discountAmount ?? 0);
  const oldGoldValue = round2(input.oldGoldValue ?? 0);
  const taxableAmount = round2(
    Math.max(0, subtotal - discountAmount - oldGoldValue),
  );
  const tax = calculateJewelleryTax(taxableAmount, input.gstPercent);
  const grandTotalRaw = round2(taxableAmount + tax.totalTax);
  const grandTotal = Math.round(grandTotalRaw);
  const roundOff = round2(grandTotal - grandTotalRaw);

  return {
    subtotal,
    discountAmount,
    oldGoldValue,
    taxableAmount,
    grandTotalRaw,
    roundOff,
    grandTotal,
    ...tax,
  };
}

export function calculateMortgageMonthlyInterest(
  principalAmount: number,
  interestRateMonthly: number,
): number {
  if (principalAmount <= 0 || interestRateMonthly <= 0) return 0;
  return round2((principalAmount * interestRateMonthly) / 100);
}

export function addLoanMonths(date: Date | string, months: number): Date {
  const source = normalizeDate(date);
  const result = new Date(
    Date.UTC(
      source.getUTCFullYear(),
      source.getUTCMonth(),
      source.getUTCDate(),
    ),
  );
  const originalDate = result.getUTCDate();
  result.setUTCMonth(result.getUTCMonth() + Math.max(0, months));

  if (result.getUTCDate() !== originalDate) {
    result.setUTCDate(0);
  }

  return result;
}

/** Completed whole months between the two dates (floor). Used for tenure and
 * the next-due-date anniversary. */
export function calculateElapsedLoanMonths(
  loanDate: Date | string,
  asOfDate: Date | string = new Date(),
): number {
  const start = normalizeDate(loanDate);
  const asOf = normalizeDate(asOfDate);
  if (asOf.getTime() < start.getTime()) return 0;

  let months =
    (asOf.getUTCFullYear() - start.getUTCFullYear()) * 12 +
    (asOf.getUTCMonth() - start.getUTCMonth());

  if (asOf.getUTCDate() < start.getUTCDate()) {
    months -= 1;
  }

  return Math.max(0, months);
}

/** The UTC calendar date (midnight timestamp) of a moment — cycle boundaries
 * compare dates, never times of day. */
function dateOnlyUtc(d: Date): number {
  return Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
}

/** Months to CHARGE interest for. Cycles run exact date-to-date (10th → 10th):
 * a month completes ON the same date of the following month, and the next
 * month is charged only after that date has PASSED. Any started month counts
 * in full — a loan 1 day old owes 1 month; 1 month + 1 day owes 2. The loan
 * day itself charges nothing yet. */
export function calculateChargeableLoanMonths(
  loanDate: Date | string,
  asOfDate: Date | string = new Date(),
): number {
  const start = normalizeDate(loanDate);
  const asOf = normalizeDate(asOfDate);
  if (dateOnlyUtc(asOf) <= dateOnlyUtc(start)) return 0;

  const completed = calculateElapsedLoanMonths(start, asOf);
  const anniversary = addLoanMonths(start, completed);
  // A new month begins only the day AFTER the anniversary date.
  return dateOnlyUtc(asOf) > dateOnlyUtc(anniversary)
    ? completed + 1
    : completed;
}

export function calculateMortgagePayable(
  input: MortgagePayableInput,
): MortgagePayableBreakdown {
  const principalAmount = Math.max(0, input.principalAmount);
  const interestRateMonthly = Math.max(0, input.interestRateMonthly);
  const interestPaid = round2(Math.max(0, input.interestPaid ?? 0));
  const principalPaid = round2(
    Math.min(principalAmount, Math.max(0, input.principalPaid ?? 0)),
  );
  const asOf = input.asOfDate ?? new Date();
  const completedMonths = calculateElapsedLoanMonths(input.loanDate, asOf);
  // Interest is billed per started month (rounded up), so `elapsedMonths` here
  // is the number of months charged.
  const elapsedMonths = calculateChargeableLoanMonths(input.loanDate, asOf);
  const outstandingPrincipal = round2(
    Math.max(0, principalAmount - principalPaid),
  );

  // Each cycle's interest is computed on the principal outstanding at that
  // cycle's start: payments dated on/before the anniversary that opens a cycle
  // reduce it; a mid-cycle payment reduces only the NEXT cycle.
  let accruedInterestAmount: number;
  const history = input.principalPayments;
  if (history === undefined) {
    // Legacy flat model: rate × original principal × charged months.
    accruedInterestAmount = round2(
      calculateMortgageMonthlyInterest(principalAmount, interestRateMonthly) *
        elapsedMonths,
    );
  } else {
    const payments = history
      .map((p) => ({
        amount: Math.max(0, p.amount),
        dateOnly: dateOnlyUtc(normalizeDate(p.date)),
      }))
      .filter((p) => p.amount > 0);
    let accrued = 0;
    for (let cycle = 1; cycle <= elapsedMonths; cycle += 1) {
      const cycleStart = dateOnlyUtc(addLoanMonths(input.loanDate, cycle - 1));
      const paidByCycleStart = payments.reduce(
        (sum, p) => (p.dateOnly <= cycleStart ? sum + p.amount : sum),
        0,
      );
      const cyclePrincipal = Math.max(0, principalAmount - paidByCycleStart);
      accrued += calculateMortgageMonthlyInterest(
        cyclePrincipal,
        interestRateMonthly,
      );
    }
    accruedInterestAmount = round2(accrued);
  }

  const pendingInterestAmount = round2(
    Math.max(0, accruedInterestAmount - interestPaid),
  );
  // "Monthly interest" is what the NEXT month will cost — on the outstanding
  // principal, not the original.
  const monthlyInterestAmount = calculateMortgageMonthlyInterest(
    outstandingPrincipal,
    interestRateMonthly,
  );

  return {
    elapsedMonths,
    monthlyInterestAmount,
    accruedInterestAmount,
    interestPaid,
    pendingInterestAmount,
    principalPaid,
    outstandingPrincipal,
    totalPayableAmount: round2(outstandingPrincipal + pendingInterestAmount),
    nextDueDate: addLoanMonths(input.loanDate, completedMonths + 1),
  };
}

function normalizeDate(value: Date | string): Date {
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new Error("Invalid date");
  }
  return date;
}
