import {
  calculateInvoiceTotals,
  calculateItemPrice,
  calculateJewelleryTax,
  calculateMortgageMonthlyInterest,
  calculateMortgagePayable,
  calculateOldGoldValue,
} from "./index";

describe("business logic", () => {
  it("calculates jewellery tax at 3%", () => {
    expect(calculateJewelleryTax(1000)).toEqual({
      cgstPercent: 1.5,
      cgstAmount: 15,
      sgstPercent: 1.5,
      sgstAmount: 15,
      totalTax: 30,
    });
  });

  it("calculates old gold exchange value", () => {
    expect(calculateOldGoldValue(10.5, 6500)).toBe(68250);
  });

  it("calculates item price with wastage and stones", () => {
    expect(
      calculateItemPrice({
        netWeight: 10,
        ratePerGram: 6500,
        makingCharges: 2000,
        stoneValue: 1500,
        wastagePercent: 5,
      }),
    ).toEqual({
      metalValue: 65000,
      makingCharges: 2000,
      stoneValue: 1500,
      wastageValue: 3250,
      itemTotal: 71750,
    });
  });

  it("calculates invoice totals with exchange, discount, tax, and roundoff", () => {
    expect(
      calculateInvoiceTotals({
        itemTotals: [50000, 25750],
        discountAmount: 750,
        oldGoldValue: 10000,
      }),
    ).toEqual({
      subtotal: 75750,
      discountAmount: 750,
      oldGoldValue: 10000,
      taxableAmount: 65000,
      cgstPercent: 1.5,
      cgstAmount: 975,
      sgstPercent: 1.5,
      sgstAmount: 975,
      totalTax: 1950,
      grandTotalRaw: 66950,
      roundOff: 0,
      grandTotal: 66950,
    });
  });

  it("calculates mortgage monthly interest", () => {
    expect(calculateMortgageMonthlyInterest(100000, 2)).toBe(2000);
  });

  it("calculates mortgage payable after completed loan months", () => {
    expect(
      calculateMortgagePayable({
        principalAmount: 100000,
        interestRateMonthly: 2,
        loanDate: "2026-01-10T00:00:00.000Z",
        asOfDate: "2026-04-10T00:00:00.000Z",
        interestPaid: 2500,
        principalPaid: 10000,
      }),
    ).toEqual({
      elapsedMonths: 3,
      // Monthly interest reflects what the NEXT month costs — on the
      // outstanding 90,000, not the original principal.
      monthlyInterestAmount: 1800,
      accruedInterestAmount: 6000,
      interestPaid: 2500,
      pendingInterestAmount: 3500,
      principalPaid: 10000,
      outstandingPrincipal: 90000,
      totalPayableAmount: 93500,
      nextDueDate: new Date("2026-05-10T00:00:00.000Z"),
    });
  });

  it("completes a month only after the same date next month passes", () => {
    const base = {
      principalAmount: 100000,
      interestRateMonthly: 2,
      loanDate: "2026-01-10T00:00:00.000Z",
    };
    // On the anniversary DAY the first month completes — still 1 month.
    expect(
      calculateMortgagePayable({
        ...base,
        asOfDate: "2026-02-10T18:30:00.000Z",
      }).elapsedMonths,
    ).toBe(1);
    // The day AFTER the anniversary starts month 2.
    expect(
      calculateMortgagePayable({
        ...base,
        asOfDate: "2026-02-11T00:00:00.000Z",
      }).elapsedMonths,
    ).toBe(2);
  });

  it("clamps month-end anniversaries (31st → 28th/29th)", () => {
    const base = {
      principalAmount: 100000,
      interestRateMonthly: 2,
      loanDate: "2026-01-31T00:00:00.000Z",
    };
    // Feb 28 is the clamped anniversary — month 1 completes there.
    expect(
      calculateMortgagePayable({
        ...base,
        asOfDate: "2026-02-28T12:00:00.000Z",
      }).elapsedMonths,
    ).toBe(1);
    // Mar 1 starts month 2.
    expect(
      calculateMortgagePayable({
        ...base,
        asOfDate: "2026-03-01T00:00:00.000Z",
      }).elapsedMonths,
    ).toBe(2);
  });

  it("accrues each cycle on the principal outstanding at its start", () => {
    // ₹50,000 @ 2%: month 1 on 50k = 1000; ₹10,000 principal repaid on the
    // first anniversary → month 2 on 40k = 800.
    const breakdown = calculateMortgagePayable({
      principalAmount: 50000,
      interestRateMonthly: 2,
      loanDate: "2026-01-10T00:00:00.000Z",
      asOfDate: "2026-02-15T00:00:00.000Z",
      principalPaid: 10000,
      principalPayments: [{ amount: 10000, date: "2026-02-10T00:00:00.000Z" }],
    });
    expect(breakdown.elapsedMonths).toBe(2);
    expect(breakdown.accruedInterestAmount).toBe(1800);
    expect(breakdown.outstandingPrincipal).toBe(40000);
    expect(breakdown.monthlyInterestAmount).toBe(800);
  });

  it("a mid-cycle principal payment reduces only the NEXT cycle", () => {
    // Payment lands on Feb 15 — cycle 2 (opened Feb 10) was already charged on
    // the full 50k; cycle 3 (opens Mar 10) accrues on 40k.
    const base = {
      principalAmount: 50000,
      interestRateMonthly: 2,
      loanDate: "2026-01-10T00:00:00.000Z",
      principalPaid: 10000,
      principalPayments: [{ amount: 10000, date: "2026-02-15T00:00:00.000Z" }],
    };
    const cycle2 = calculateMortgagePayable({
      ...base,
      asOfDate: "2026-02-20T00:00:00.000Z",
    });
    expect(cycle2.elapsedMonths).toBe(2);
    expect(cycle2.accruedInterestAmount).toBe(2000); // 1000 + 1000 (unchanged)

    const cycle3 = calculateMortgagePayable({
      ...base,
      asOfDate: "2026-03-11T00:00:00.000Z",
    });
    expect(cycle3.elapsedMonths).toBe(3);
    expect(cycle3.accruedInterestAmount).toBe(2800); // 1000 + 1000 + 800
  });

  it("charges a full month from day one (any started month counts)", () => {
    // 29 days in → still within the first month, but a started month is a full
    // month, so one month's interest is due.
    const partial = calculateMortgagePayable({
      principalAmount: 50000,
      interestRateMonthly: 1.5,
      loanDate: "2026-01-10T00:00:00.000Z",
      asOfDate: "2026-02-09T00:00:00.000Z",
    });
    expect(partial.elapsedMonths).toBe(1);
    expect(partial.pendingInterestAmount).toBe(750);

    // A brand-new loan (same day) owes nothing yet.
    expect(
      calculateMortgagePayable({
        principalAmount: 50000,
        interestRateMonthly: 1.5,
        loanDate: "2026-01-10T00:00:00.000Z",
        asOfDate: "2026-01-10T00:00:00.000Z",
      }).elapsedMonths,
    ).toBe(0);
  });

  it("rounds a part-month up to the next full month", () => {
    // 1 month + 2 days → 2 months of interest.
    const breakdown = calculateMortgagePayable({
      principalAmount: 100000,
      interestRateMonthly: 2,
      loanDate: "2026-01-10T00:00:00.000Z",
      asOfDate: "2026-02-12T00:00:00.000Z",
    });
    expect(breakdown.elapsedMonths).toBe(2);
    expect(breakdown.accruedInterestAmount).toBe(4000);
  });
});
