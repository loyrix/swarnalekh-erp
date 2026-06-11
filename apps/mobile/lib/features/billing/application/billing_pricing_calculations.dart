class BillingLineBreakdown {
  const BillingLineBreakdown({
    required this.productValue,
    required this.makingCharges,
    required this.gst,
    required this.lineTotal,
    required this.finalTotal,
    required this.usesExplicitSellingPrice,
  });

  final double productValue;
  final double makingCharges;
  final double gst;
  final double lineTotal;
  final double finalTotal;
  final bool usesExplicitSellingPrice;
}

double _round2(double value) => ((value + 0.000000001) * 100).round() / 100;

BillingLineBreakdown calculateBillingLineBreakdown({
  required int quantity,
  required double sellingPrice,
  required double currentRatePerGram,
  required double grossWeight,
  required double netWeight,
  required double makingChargesFixed,
  required double makingChargesPerGram,
  required double makingChargesPercent,
  required double stoneValue,
  required double wastagePercent,
}) {
  final safeQuantity = quantity < 1 ? 1 : quantity;
  final totalGrossWeight = grossWeight * safeQuantity;
  final totalNetWeight = netWeight * safeQuantity;
  final calculatedMetalValue = _round2(currentRatePerGram * totalNetWeight);
  final fixedMaking = makingChargesFixed * safeQuantity;
  final perGramMaking = makingChargesPerGram * totalGrossWeight;
  final percentMaking = makingChargesPercent > 0
      ? (calculatedMetalValue * makingChargesPercent) / 100
      : 0.0;
  final makingCharges = _round2(
    perGramMaking > 0
        ? perGramMaking
        : (fixedMaking > 0 ? fixedMaking : percentMaking),
  );
  final lineStoneValue = _round2(stoneValue * safeQuantity);
  final wastageValue = wastagePercent > 0
      ? _round2((calculatedMetalValue * wastagePercent) / 100)
      : 0.0;

  if (sellingPrice > 0) {
    final lineTotal = _round2(sellingPrice * safeQuantity);
    final productValue = _round2(
      (lineTotal - makingCharges - lineStoneValue - wastageValue).clamp(
        0,
        double.infinity,
      ),
    );
    final gst = _round2(lineTotal * 0.03);
    return BillingLineBreakdown(
      productValue: productValue,
      makingCharges: makingCharges,
      gst: gst,
      lineTotal: lineTotal,
      finalTotal: _round2(lineTotal + gst),
      usesExplicitSellingPrice: true,
    );
  }

  final lineTotal = _round2(
    calculatedMetalValue + makingCharges + wastageValue + lineStoneValue,
  );
  final gst = _round2(lineTotal * 0.03);
  return BillingLineBreakdown(
    productValue: calculatedMetalValue,
    makingCharges: makingCharges,
    gst: gst,
    lineTotal: lineTotal,
    finalTotal: _round2(lineTotal + gst),
    usesExplicitSellingPrice: false,
  );
}
