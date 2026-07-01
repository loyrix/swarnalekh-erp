import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/reports/presentation/widgets/report_section.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/compact_data_row.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildLightTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('ReportSection', () {
    testWidgets('renders title, metric, and rows as CompactDataRow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ReportSection(
            title: 'Current Stock',
            subtitle: 'Gold + Silver',
            emptyText: 'No stock',
            metricValue: '2',
            rows: const [
              ReportRow(
                leadingIcon: Icons.diamond_outlined,
                title: 'Gold Ring',
                subtitle: 'Ring • RNG-1',
                statusLabel: 'In stock',
                metrics: [('Net', '4.2g'), ('Price', '₹32,000')],
              ),
              ReportRow(
                leadingIcon: Icons.diamond_outlined,
                title: 'Silver Coin',
                subtitle: 'Coin • CN-1',
                statusLabel: 'In stock',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Current Stock'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.byType(CompactDataRow), findsNWidgets(2));
      expect(find.text('Gold Ring'), findsOneWidget);
      expect(find.text('Silver Coin'), findsOneWidget);
    });

    testWidgets('shows the empty text when there are no rows', (tester) async {
      await tester.pumpWidget(
        _host(
          const ReportSection(
            title: 'Low Stock',
            subtitle: 'Items running low',
            emptyText: 'Nothing low on stock',
            rows: [],
          ),
        ),
      );

      expect(find.text('Nothing low on stock'), findsOneWidget);
      expect(find.byType(CompactDataRow), findsNothing);
    });
  });
}
