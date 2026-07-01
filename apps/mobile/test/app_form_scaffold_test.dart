import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_form_scaffold.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildLightTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  group('AppFormScaffold', () {
    testWidgets('renders title, fields, and footer', (tester) async {
      await tester.pumpWidget(
        _host(
          AppFormScaffold(
            title: 'Add Stock',
            footer: const Text('TOTAL ₹100'),
            onSave: () {},
            children: const [Text('Field A'), Text('Field B')],
          ),
        ),
      );

      expect(find.text('Add Stock'), findsOneWidget);
      expect(find.text('Field A'), findsOneWidget);
      expect(find.text('Field B'), findsOneWidget);
      expect(find.text('TOTAL ₹100'), findsOneWidget);
    });

    testWidgets('save button fires onSave', (tester) async {
      var saved = 0;
      await tester.pumpWidget(
        _host(
          AppFormScaffold(
            title: 'Form',
            onSave: () => saved++,
            children: const [Text('x')],
          ),
        ),
      );

      await tester.tap(find.text('Save'));
      expect(saved, 1);
    });

    testWidgets('save is disabled while saving and shows a spinner', (
      tester,
    ) async {
      var saved = 0;
      await tester.pumpWidget(
        _host(
          AppFormScaffold(
            title: 'Form',
            isSaving: true,
            onSave: () => saved++,
            children: const [Text('x')],
          ),
        ),
      );
      await tester.pump();

      // Spinner shown; the save button is the loading one and is disabled.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final buttons = tester
          .widgetList<GoldButton>(find.byType(GoldButton))
          .toList();
      final saveButton = buttons.firstWhere((b) => b.isLoading);
      expect(saveButton.onPressed, isNull);
      expect(saved, 0);
    });

    testWidgets('close pops the route', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppFormScaffold.push<void>(
                context,
                builder: (_) => AppFormScaffold(
                  title: 'Pushed',
                  onSave: () {},
                  children: const [Text('field')],
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Pushed'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Pushed'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });
}
