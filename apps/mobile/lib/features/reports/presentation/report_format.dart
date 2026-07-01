import 'package:intl/intl.dart';

final NumberFormat _inr = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String reportMoney(num? value) => _inr.format(value ?? 0);

String reportWeight(double? value) {
  final weight = value ?? 0;
  if (weight == 0) return '0g';
  return '${weight.toStringAsFixed(3)}g';
}

String reportDate(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return '-';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return '-';
  return DateFormat('dd MMM yyyy').format(parsed);
}

String reportFallback(String? value, String fallback) =>
    (value == null || value.isEmpty) ? fallback : value;

String reportReadableStatus(String? value) {
  final text = reportFallback(value, '-');
  return text
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : part[0].toUpperCase() + part.substring(1).toLowerCase(),
      )
      .join(' ');
}
