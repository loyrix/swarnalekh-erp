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

  @override
  bool operator ==(Object other) =>
      other is StatPeriod &&
      other.kind == kind &&
      other.range?.start == range?.start &&
      other.range?.end == range?.end;

  @override
  int get hashCode => Object.hash(kind, range?.start, range?.end);
}
