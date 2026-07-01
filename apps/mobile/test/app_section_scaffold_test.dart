import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/shared/widgets/app_section_scaffold.dart';
import 'package:swarnbook/shared/widgets/section_switch.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildLightTheme(),
  home: Scaffold(body: child),
);

const _sections = [
  SectionItem(value: 'stock', label: 'Stock', icon: Icons.inventory_2_rounded),
  SectionItem(value: 'sold', label: 'Sold', icon: Icons.sell_rounded),
];

void main() {
  group('AppSectionScaffold', () {
    testWidgets('renders header, section switch, and body', (tester) async {
      await tester.pumpWidget(
        _host(
          AppSectionScaffold(
            header: const Text('HEADER'),
            sections: _sections,
            activeSection: 'stock',
            onSectionChanged: (_) {},
            body: const Text('BODY'),
          ),
        ),
      );

      expect(find.text('HEADER'), findsOneWidget);
      expect(find.text('BODY'), findsOneWidget);
      expect(find.text('Stock'), findsOneWidget);
      expect(find.text('Sold'), findsOneWidget);
    });

    testWidgets('tapping a section fires onSectionChanged', (tester) async {
      String? changed;
      await tester.pumpWidget(
        _host(
          AppSectionScaffold(
            sections: _sections,
            activeSection: 'stock',
            onSectionChanged: (v) => changed = v,
            body: const Text('BODY'),
          ),
        ),
      );

      await tester.tap(find.text('Sold'));
      await tester.pump();
      expect(changed, 'sold');
    });

    testWidgets('omits section switch when no sections provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(AppSectionScaffold(body: const Text('BODY'))),
      );
      expect(find.byType(SectionSwitch), findsNothing);
      expect(find.text('BODY'), findsOneWidget);
    });

    testWidgets('wraps body in RefreshIndicator when onRefresh set', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppSectionScaffold(
            onRefresh: () async {},
            body: ListView(children: const [Text('BODY')]),
          ),
        ),
      );
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
