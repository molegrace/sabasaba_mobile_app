import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabasaba_mobile_app/main.dart';

void main() {
  testWidgets('search results appear while typing and hide on blur', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SabaSabaApp());
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Area J1'), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'j1');
    await tester.pumpAndSettle();

    expect(find.text('Area J1'), findsWidgets);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(find.text('Area J1'), findsNothing);
  });
}
