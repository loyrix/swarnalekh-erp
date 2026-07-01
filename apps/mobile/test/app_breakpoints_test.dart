import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';

/// Pumps a probe at a fixed logical width and returns the resolved
/// [AppDensity] answers for that width.
Future<({bool compact, bool expanded, String picked})> _probe(
  WidgetTester tester,
  double width,
) async {
  late bool compact;
  late bool expanded;
  late String picked;

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: Builder(
        builder: (context) {
          compact = AppDensity.isCompact(context);
          expanded = AppDensity.isExpanded(context);
          picked = AppDensity.pick(context, compact: 'compact', wide: 'wide');
          return const SizedBox();
        },
      ),
    ),
  );

  return (compact: compact, expanded: expanded, picked: picked);
}

void main() {
  group('AppDensity', () {
    testWidgets('phone width (< compact breakpoint) is compact', (
      tester,
    ) async {
      final r = await _probe(tester, 375);
      expect(r.compact, isTrue);
      expect(r.expanded, isFalse);
      expect(r.picked, 'compact');
    });

    testWidgets('exactly at compact breakpoint is NOT compact', (tester) async {
      final r = await _probe(tester, AppBreakpoints.compact);
      expect(r.compact, isFalse);
      expect(r.picked, 'wide');
    });

    testWidgets('tablet width is not compact and not expanded', (tester) async {
      final r = await _probe(tester, 900);
      expect(r.compact, isFalse);
      expect(r.expanded, isFalse);
    });

    testWidgets('wide desktop (>= expanded breakpoint) is expanded', (
      tester,
    ) async {
      final r = await _probe(tester, 1280);
      expect(r.compact, isFalse);
      expect(r.expanded, isTrue);
      expect(r.picked, 'wide');
    });
  });
}
