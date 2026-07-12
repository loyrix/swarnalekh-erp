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

    test('value equality keys the provider family', () {
      expect(StatPeriod.today, const StatPeriod(StatPeriodKind.today));
      expect(
        StatPeriod.today == const StatPeriod(StatPeriodKind.month),
        isFalse,
      );
    });
  });
}
