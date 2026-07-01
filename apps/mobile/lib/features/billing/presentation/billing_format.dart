// Shared billing formatters so every billing widget renders money/weights/
// dates identically.

String billingMoney(double value) => '₹${value.toStringAsFixed(0)}';

String billingMoney2(double value) => '₹${value.toStringAsFixed(2)}';

String billingWeight(double value) => '${value.toStringAsFixed(3)} g';

String billingPercent(double value) => '${value.toStringAsFixed(1)}%';

/// Compact revenue for stat strips (₹1.2L / ₹3.4K / ₹500).
String billingCompactMoney(double value) {
  if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(2)}L';
  if (value >= 1000) return '₹${(value / 1000).toStringAsFixed(1)}K';
  return '₹${value.toStringAsFixed(0)}';
}

String billingDate(DateTime? value) {
  if (value == null) return '-';
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
