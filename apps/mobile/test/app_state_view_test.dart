import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_state_view.dart';

Widget _host(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

void main() {
  group('AppStateView', () {
    testWidgets('loading state renders the loading skeleton', (tester) async {
      await tester.pumpWidget(
        _host(
          AppStateView<List<String>>(
            value: const AsyncValue.loading(),
            data: (items) => Text(items.join(',')),
          ),
        ),
      );
      await tester.pump(); // let one shimmer frame settle
      // Data builder must NOT have run.
      expect(find.textContaining(','), findsNothing);
    });

    testWidgets('error state shows message and retry fires callback', (
      tester,
    ) async {
      var retried = 0;
      await tester.pumpWidget(
        _host(
          AppStateView<List<String>>(
            value: AsyncValue.error('boom', StackTrace.empty),
            onRetry: () => retried++,
            data: (items) => Text(items.join(',')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });

    testWidgets('empty state shows when isEmpty is true', (tester) async {
      await tester.pumpWidget(
        _host(
          AppStateView<List<String>>(
            value: const AsyncValue.data(<String>[]),
            isEmpty: (items) => items.isEmpty,
            data: (items) => Text('data:${items.length}'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default empty state ("no results"); data builder did not run.
      expect(find.text('data:0'), findsNothing);
      expect(find.text('No results found'), findsOneWidget);
    });

    testWidgets('data state renders the child for non-empty data', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppStateView<List<String>>(
            value: const AsyncValue.data(<String>['a', 'b']),
            isEmpty: (items) => items.isEmpty,
            data: (items) => Text('data:${items.length}'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('data:2'), findsOneWidget);
      expect(find.text('No results found'), findsNothing);
    });
  });
}
