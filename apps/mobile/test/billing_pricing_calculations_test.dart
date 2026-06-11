import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/billing/application/billing_pricing_calculations.dart';

void main() {
  group('billing pricing calculations', () {
    test('uses explicit PDF Add Stock selling price as line total', () {
      final breakdown = calculateBillingLineBreakdown(
        quantity: 1,
        sellingPrice: 59000,
        currentRatePerGram: 6000,
        grossWeight: 10,
        netWeight: 9,
        makingChargesFixed: 500,
        makingChargesPerGram: 0,
        makingChargesPercent: 0,
        stoneValue: 250,
        wastagePercent: 0,
      );

      expect(breakdown.usesExplicitSellingPrice, isTrue);
      expect(breakdown.lineTotal, 59000);
      expect(breakdown.productValue, 58250);
      expect(breakdown.makingCharges, 500);
      expect(breakdown.gst, 1770);
      expect(breakdown.finalTotal, 60770);
    });

    test('falls back to rate-based billing when no selling price is saved', () {
      final breakdown = calculateBillingLineBreakdown(
        quantity: 1,
        sellingPrice: 0,
        currentRatePerGram: 6000,
        grossWeight: 10,
        netWeight: 9,
        makingChargesFixed: 500,
        makingChargesPerGram: 0,
        makingChargesPercent: 0,
        stoneValue: 250,
        wastagePercent: 0,
      );

      expect(breakdown.usesExplicitSellingPrice, isFalse);
      expect(breakdown.productValue, 54000);
      expect(breakdown.lineTotal, 54750);
      expect(breakdown.gst, 1642.5);
      expect(breakdown.finalTotal, 56392.5);
    });
  });
}
