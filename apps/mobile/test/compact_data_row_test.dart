import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildLightTheme(),
  home: Scaffold(body: child),
);

void main() {
  group('CompactDataRow (Stage V)', () {
    testWidgets('renders a word-labelled first metric as a trailing figure', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CompactDataRow(
            title: 'Gold Ring',
            subtitle: 'RING-7',
            metrics: [('Paid', '₹500')],
          ),
        ),
      );

      expect(find.text('Gold Ring'), findsOneWidget);
      expect(find.text('₹500'), findsOneWidget); // value
      expect(find.text('Paid'), findsOneWidget); // caption
    });

    testWidgets('fuses a short symbol label onto the value', (tester) async {
      await tester.pumpWidget(
        _host(const CompactDataRow(title: 'Asha', metrics: [('₹', '1.5L')])),
      );

      // Symbol + value render as a single fused figure, not two texts.
      expect(find.text('₹1.5L'), findsOneWidget);
      expect(find.text('₹'), findsNothing);
    });

    testWidgets('derives the left accent from a StatusBadge trailing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CompactDataRow(
            title: 'Item',
            trailing: StatusBadge(label: 'in_stock'),
          ),
        ),
      );

      // A 3px accent stripe painted in the badge's success colour is present.
      final accent = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == AppColors.success,
      );
      expect(accent, findsOneWidget);
    });

    testWidgets('shows no accent when there is no colour source', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CompactDataRow(title: 'Plain', subtitle: 'no status')),
      );
      expect(find.text('Plain'), findsOneWidget);
      final anyAccent = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == AppColors.success,
      );
      expect(anyAccent, findsNothing);
    });
  });
}
