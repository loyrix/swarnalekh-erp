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

/// Elapsed tenure between the pledge date and [asOf] (default: now), rendered
/// compactly as "1y 2m 5d" (zero leading parts dropped). Answers the shop's
/// "how long has it been?" question.
String mortgageTenure(String? loanDate, {DateTime? asOf}) {
  if (loanDate == null || loanDate.isEmpty) return '-';
  final start = DateTime.tryParse(loanDate);
  if (start == null) return '-';
  var end = asOf ?? DateTime.now();
  if (end.isBefore(start)) end = start;

  var years = end.year - start.year;
  var months = end.month - start.month;
  var days = end.day - start.day;
  if (days < 0) {
    months -= 1;
    // Days in the month before `end` gives the borrow amount.
    days += DateTime(end.year, end.month, 0).day;
  }
  if (months < 0) {
    years -= 1;
    months += 12;
  }

  final parts = <String>[
    if (years > 0) '${years}y',
    if (months > 0) '${months}m',
    if (days > 0 || (years == 0 && months == 0)) '${days}d',
  ];
  return parts.join(' ');
}
