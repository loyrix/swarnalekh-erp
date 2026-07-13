import 'package:flutter/material.dart';

/// A time window for period-sensitive dashboard figures (mortgage collections,
/// inventory sold, …). Maps to the API's `period`/`dateFrom`/`dateTo` params.
enum StatPeriodKind {
  today,
  month,
  threeMonths,
  sixMonths,
  twelveMonths,
  all,
  custom,
}

@immutable
class StatPeriod {
  const StatPeriod(this.kind, {this.range});

  final StatPeriodKind kind;

  /// Only set when [kind] is [StatPeriodKind.custom].
  final DateTimeRange? range;

  static const today = StatPeriod(StatPeriodKind.today);
  static const month = StatPeriod(StatPeriodKind.month);

  String get apiPeriod => switch (kind) {
    StatPeriodKind.today => 'today',
    StatPeriodKind.month => 'month',
    StatPeriodKind.threeMonths => '3months',
    StatPeriodKind.sixMonths => '6months',
    StatPeriodKind.twelveMonths => '12months',
    StatPeriodKind.all => 'all',
    StatPeriodKind.custom => 'custom',
  };

  /// Query parameters for the dashboard/stats endpoints. A custom period with
  /// no range falls back to all-time.
  Map<String, dynamic> toQueryParameters() {
    if (kind == StatPeriodKind.custom) {
      final r = range;
      if (r == null) return {'period': 'all'};
      return {
        'period': 'custom',
        'dateFrom': _isoDate(r.start),
        'dateTo': _isoDate(r.end),
      };
    }
    return {'period': apiPeriod};
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Resolves this period to a concrete date range (null = all time), for
  /// endpoints that only accept dateFrom/dateTo. Mirrors the API's
  /// resolveDateRange presets.
  DateTimeRange? resolveRange([DateTime? clock]) {
    final now = clock ?? DateTime.now();
    DateTime dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
    switch (kind) {
      case StatPeriodKind.all:
        return null;
      case StatPeriodKind.custom:
        return range;
      case StatPeriodKind.today:
        return DateTimeRange(start: dayStart(now), end: now);
      case StatPeriodKind.month:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case StatPeriodKind.threeMonths:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 3, now.day),
          end: now,
        );
      case StatPeriodKind.sixMonths:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 6, now.day),
          end: now,
        );
      case StatPeriodKind.twelveMonths:
        return DateTimeRange(
          start: DateTime(now.year - 1, now.month, now.day),
          end: now,
        );
    }
  }

  /// dateFrom/dateTo strings for query params, or empty for all-time.
  Map<String, String> toDateQueryParameters([DateTime? clock]) {
    final resolved = resolveRange(clock);
    if (resolved == null) return const {};
    return {
      'dateFrom': _isoDate(resolved.start),
      'dateTo': _isoDate(resolved.end),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is StatPeriod &&
      other.kind == kind &&
      other.range?.start == range?.start &&
      other.range?.end == range?.end;

  @override
  int get hashCode => Object.hash(kind, range?.start, range?.end);
}
