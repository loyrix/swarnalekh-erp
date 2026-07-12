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

export interface MortgagePayableInput {
  principalAmount: number;
  interestRateMonthly: number;
  loanDate: Date | string;
  asOfDate?: Date | string;
  interestPaid?: number;
  principalPaid?: number;
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
): JewelleryTaxBreakdown {
  const safeTaxableAmount = Math.max(0, taxableAmount);
  const cgstPercent = 1.5;
  const sgstPercent = 1.5;
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
  const tax = calculateJewelleryTax(taxableAmount);
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

/** Months to CHARGE interest for: any started month counts as a full month
 * (rounded up), including the first — so a loan even 1 day old owes 1 month and
 * 1 month + 2 days owes 2 months. */
export function calculateChargeableLoanMonths(
  loanDate: Date | string,
  asOfDate: Date | string = new Date(),
): number {
  const start = normalizeDate(loanDate);
  const asOf = normalizeDate(asOfDate);
  if (asOf.getTime() <= start.getTime()) return 0;

  const completed = calculateElapsedLoanMonths(start, asOf);
  const anniversary = addLoanMonths(start, completed);
  // Any time past the last completed-month anniversary starts a new month.
  return asOf.getTime() > anniversary.getTime() ? completed + 1 : completed;
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
  const monthlyInterestAmount = calculateMortgageMonthlyInterest(
    principalAmount,
    interestRateMonthly,
  );
  const accruedInterestAmount = round2(monthlyInterestAmount * elapsedMonths);
  const pendingInterestAmount = round2(
    Math.max(0, accruedInterestAmount - interestPaid),
  );
  const outstandingPrincipal = round2(
    Math.max(0, principalAmount - principalPaid),
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
