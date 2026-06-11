import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/inventory/application/inventory_pricing_calculations.dart';

void main() {
  test('calculates PDF Add Stock net weight from gross and stone weight', () {
    expect(
      calculateInventoryNetWeight(grossWeight: 12.750, stoneWeight: 0.625),
      12.125,
    );
    expect(calculateInventoryNetWeight(grossWeight: 2.5, stoneWeight: 3), 0);
  });

  test('calculates PDF Add Stock making charges by mode', () {
    expect(
      calculateInventoryMakingCharges(
        netWeight: 10,
        purchasePrice: 6000,
        makingValue: 250,
        makingMode: inventoryMakingModePerGram,
      ),
      2500,
    );
    expect(
      calculateInventoryMakingCharges(
        netWeight: 10,
        purchasePrice: 6000,
        makingValue: 1800,
        makingMode: inventoryMakingModeFixed,
      ),
      1800,
    );
    expect(
      calculateInventoryMakingCharges(
        netWeight: 10,
        purchasePrice: 6000,
        makingValue: 12,
        makingMode: inventoryMakingModePercentage,
      ),
      7200,
    );
  });

  test('calculates PDF Add Stock final selling price', () {
    final makingCharges = calculateInventoryMakingCharges(
      netWeight: 9,
      purchasePrice: 6000,
      makingValue: 100,
      makingMode: inventoryMakingModePerGram,
    );

    expect(
      calculateInventoryFinalSellingPrice(
        netWeight: 9,
        purchasePrice: 6000,
        makingCharges: makingCharges,
      ),
      54900,
    );
  });

  test('splits and composes gram and milligram weight inputs', () {
    final split = splitInventoryWeight(12.125);

    expect(split.grams, '12');
    expect(split.milligrams, '125');
    expect(composeInventoryWeight(split.grams, split.milligrams), 12.125);
  });
}
