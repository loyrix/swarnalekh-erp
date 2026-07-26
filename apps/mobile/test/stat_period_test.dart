import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/shared/application/stat_period.dart';

void main() {
  group('StatPeriod.toQueryParameters', () {
    test('maps presets to the api period string', () {
      expect(StatPeriod.today.toQueryParameters(), {'period': 'today'});
      expect(StatPeriod.month.toQueryParameters(), {'period': 'month'});
      expect(const StatPeriod(StatPeriodKind.sixMonths).toQueryParameters(), {
        'period': '6months',
      });
      expect(const StatPeriod(StatPeriodKind.all).toQueryParameters(), {
        'period': 'all',
      });
    });

    test('emits from/to for a custom range', () {
      final range = DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 3, 31),
      );
      expect(
        StatPeriod(StatPeriodKind.custom, range: range).toQueryParameters(),
        {'period': 'custom', 'dateFrom': '2026-01-01', 'dateTo': '2026-03-31'},
      );
    });

    test('a custom period with no range falls back to all-time', () {
      expect(const StatPeriod(StatPeriodKind.custom).toQueryParameters(), {
        'period': 'all',
      });
    });

    test('maps the new presets to their api period strings', () {
      expect(const StatPeriod(StatPeriodKind.yesterday).toQueryParameters(), {
        'period': 'yesterday',
      });
      expect(const StatPeriod(StatPeriodKind.last7).toQueryParameters(), {
        'period': 'last7',
      });
      expect(const StatPeriod(StatPeriodKind.last30).toQueryParameters(), {
        'period': 'last30',
      });
      expect(const StatPeriod(StatPeriodKind.lastMonth).toQueryParameters(), {
        'period': 'lastmonth',
      });
      expect(
        const StatPeriod(StatPeriodKind.financialYear).toQueryParameters(),
        {'period': 'financialyear'},
      );
    });

    test('value equality keys the provider family', () {
      expect(StatPeriod.today, const StatPeriod(StatPeriodKind.today));
      expect(
        StatPeriod.today == const StatPeriod(StatPeriodKind.month),
        isFalse,
      );
    });
  });

  group('StatPeriod.resolveRange', () {
    final clock = DateTime(2026, 6, 15, 14, 30); // Mon 15 Jun 2026

    test('last 7 days is an inclusive window ending today', () {
      final r = const StatPeriod(StatPeriodKind.last7).resolveRange(clock)!;
      expect(r.start, DateTime(2026, 6, 9));
    });

    test('last month is the whole previous calendar month', () {
      final r = const StatPeriod(StatPeriodKind.lastMonth).resolveRange(clock)!;
      expect(r.start, DateTime(2026, 5, 1));
      expect(r.end, DateTime(2026, 5, 31));
    });

    test('financial year starts on 1 April', () {
      final r = const StatPeriod(
        StatPeriodKind.financialYear,
      ).resolveRange(clock)!;
      expect(r.start, DateTime(2026, 4, 1));
      // A January date belongs to the FY that began the previous April.
      final jan = const StatPeriod(
        StatPeriodKind.financialYear,
      ).resolveRange(DateTime(2026, 1, 10))!;
      expect(jan.start, DateTime(2025, 4, 1));
    });
  });
}
