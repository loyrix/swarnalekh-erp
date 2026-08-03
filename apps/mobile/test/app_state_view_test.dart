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

    // The search bug: a family provider keyed by the query starts a *new*
    // instance on every keystroke, so it arrives as loading-with-no-value. If
    // that blanks the body, the whole page (search field included) reloads
    // while the user is still typing.
    group('keeps the previous result while the next one loads', () {
      testWidgets('does not fall back to the skeleton mid-search', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            AppStateView<List<String>>(
              value: const AsyncValue.data(<String>['a', 'b']),
              data: (items) => Text('data:${items.length}'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('data:2'), findsOneWidget);

        // Query changed → brand-new provider, loading with no value of its own.
        await tester.pumpWidget(
          _host(
            AppStateView<List<String>>(
              value: const AsyncValue<List<String>>.loading(),
              data: (items) => Text('data:${items.length}'),
            ),
          ),
        );
        await tester.pump();

        // Previous results stay put, with a progress hairline over them.
        expect(find.text('data:2'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('swaps in the new result once it arrives', (tester) async {
        await tester.pumpWidget(
          _host(
            AppStateView<List<String>>(
              value: const AsyncValue.data(<String>['a', 'b']),
              data: (items) => Text('data:${items.length}'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          _host(
            AppStateView<List<String>>(
              value: const AsyncValue.data(<String>['c']),
              data: (items) => Text('data:${items.length}'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('data:1'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
      });

      testWidgets('a search matching nothing shows the empty state, not stale '
          'rows', (tester) async {
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

        expect(find.text('data:2'), findsNothing);
        expect(find.text('No results found'), findsOneWidget);
      });

      testWidgets('resetKey drops the retained value on a section switch', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            AppStateView<List<String>>(
              resetKey: 'stock',
              value: const AsyncValue.data(<String>['a', 'b']),
              data: (items) => Text('data:${items.length}'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          _host(
            AppStateView<List<String>>(
              resetKey: 'sold',
              value: const AsyncValue<List<String>>.loading(),
              data: (items) => Text('data:${items.length}'),
            ),
          ),
        );
        await tester.pump();

        // Unrelated content — the old section's rows must not linger.
        expect(find.text('data:2'), findsNothing);
      });

      testWidgets('first load with nothing retained still shows the skeleton', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            AppStateView<List<String>>(
              value: const AsyncValue<List<String>>.loading(),
              data: (items) => Text('data:${items.length}'),
            ),
          ),
        );
        await tester.pump();

        expect(find.textContaining('data:'), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
      });

      testWidgets('an error with results on screen surfaces the error view', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            AppStateView<List<String>>(
              value: const AsyncValue.data(<String>['a']),
              data: (items) => Text('data:${items.length}'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          _host(
            AppStateView<List<String>>(
              value: AsyncValue<List<String>>.error('boom', StackTrace.empty),
              data: (items) => Text('data:${items.length}'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('data:1'), findsNothing);
        expect(find.textContaining('boom'), findsWidgets);
      });
    });
  });
}
