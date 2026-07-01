import 'package:intl/intl.dart';

final NumberFormat _inr = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String mortgageMoney(num? value) => _inr.format(value ?? 0);

String mortgageDate(String? value) {
  if (value == null || value.isEmpty) return '-';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return '-';
  return DateFormat('dd MMM yyyy').format(parsed);
}
