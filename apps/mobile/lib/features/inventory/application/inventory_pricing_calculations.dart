const String inventoryMakingModePerGram = 'per_gram';
const String inventoryMakingModeFixed = 'fixed';
const String inventoryMakingModePercentage = 'percentage';

({String grams, String milligrams}) splitInventoryWeight(dynamic rawWeight) {
  final value = double.tryParse(rawWeight?.toString() ?? '') ?? 0;
  final totalMg = (value * 1000).round();
  final grams = totalMg ~/ 1000;
  final mg = totalMg % 1000;
  return (grams: grams.toString(), milligrams: mg == 0 ? '' : mg.toString());
}

double composeInventoryWeight(String grams, String milligrams) {
  final g = int.tryParse(grams.trim()) ?? 0;
  final mg = int.tryParse(milligrams.trim()) ?? 0;
  return g + (mg / 1000);
}

double calculateInventoryNetWeight({
  required double grossWeight,
  required double stoneWeight,
}) {
  final netWeight = grossWeight - stoneWeight;
  return netWeight < 0 ? 0 : netWeight;
}

double calculateInventoryMakingCharges({
  required double netWeight,
  required double purchasePrice,
  required double makingValue,
  required String makingMode,
}) {
  if (makingValue <= 0) return 0;
  if (makingMode == inventoryMakingModeFixed) return makingValue;
  if (makingMode == inventoryMakingModePercentage) {
    return (netWeight * purchasePrice * makingValue) / 100;
  }
  return netWeight * makingValue;
}

double calculateInventoryFinalSellingPrice({
  required double netWeight,
  required double purchasePrice,
  required double makingCharges,
}) {
  return (netWeight * purchasePrice) + makingCharges;
}
