import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/shared/widgets/keyboard_aware.dart';

void main() {
  testWidgets('KeyboardDismissRegion dismisses focused input on outside tap', (
    tester,
  ) async {
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: KeyboardDismissRegion(
          child: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: focusNode),
                Container(
                  key: Key('outside-area'),
                  width: 240,
                  height: 240,
                  color: Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byKey(const Key('outside-area')));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);

    focusNode.dispose();
  });

  testWidgets('KeyboardAwareScrollView adds keyboard inset to bottom padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: 240)),
          child: KeyboardAwareScrollView(
            padding: EdgeInsets.all(16),
            child: SizedBox(height: 900),
          ),
        ),
      ),
    );

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    final padding = scrollView.padding! as EdgeInsets;

    expect(
      scrollView.keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.onDrag,
    );
    expect(padding.bottom, 256);
  });
}
