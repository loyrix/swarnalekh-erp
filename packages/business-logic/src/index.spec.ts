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
      monthlyInterestAmount: 2000,
      accruedInterestAmount: 6000,
      interestPaid: 2500,
      pendingInterestAmount: 3500,
      principalPaid: 10000,
      outstandingPrincipal: 90000,
      totalPayableAmount: 93500,
      nextDueDate: new Date("2026-05-10T00:00:00.000Z"),
    });
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
