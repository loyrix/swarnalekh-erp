import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_detail_sheet.dart';
import 'package:swarnbook/shared/widgets/app_filter_sheet.dart';

Widget _host(Widget home) => MaterialApp(
  theme: buildLightTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  group('AppDetailSheet', () {
    testWidgets('shows title, sections, rows, and closes', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => AppDetailSheet.show(
                    context,
                    title: 'Gold Ring',
                    subtitle: 'RNG-001',
                    sections: const [
                      AppDetailSection(
                        heading: 'Weight',
                        rows: [
                          AppDetailRow('Net', '4.20 g'),
                          AppDetailRow('Total', '₹32,000', emphasize: true),
                        ],
                      ),
                    ],
                    actions: [const Text('ACTION')],
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Gold Ring'), findsOneWidget);
      expect(find.text('RNG-001'), findsOneWidget);
      expect(find.text('WEIGHT'), findsOneWidget); // heading upper-cased
      expect(find.text('Net'), findsOneWidget);
      expect(find.text('₹32,000'), findsOneWidget);
      expect(find.text('ACTION'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Gold Ring'), findsNothing);
    });
  });

  group('AppFilterSheet', () {
    testWidgets('renders controls; Apply fires callback and closes', (
      tester,
    ) async {
      var applied = 0;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => AppFilterSheet.show(
                    context,
                    onApply: () => applied++,
                    builder: (context, setSheetState) => const [
                      Text('CATEGORY FILTER'),
                    ],
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('CATEGORY FILTER'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(applied, 1);
      expect(find.text('CATEGORY FILTER'), findsNothing); // sheet dismissed
    });
  });
}
