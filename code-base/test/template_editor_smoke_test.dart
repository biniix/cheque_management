import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cheque_management/screens/template_editor_screen.dart';

void main() {
  testWidgets('template editor: panels present, bank name renders live',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: TemplateEditorScreen()),
      ),
    );

    expect(find.text('FIELDS'), findsOneWidget);
    expect(find.text('PROPERTIES'), findsOneWidget);
    expect(find.text('Bank Name'), findsWidgets); // FIELDS tile

    await tester.tap(find.text('Bank'));
    await tester.pumpAndSettle();

    expect(find.text('Commercial Bank of Ethiopia'), findsOneWidget);
    expect(find.text('Awash Bank'), findsOneWidget);

    await tester.tap(find.text('Commercial Bank of Ethiopia').last);
    await tester.pumpAndSettle();

    expect(find.text('Commercial Bank of Ethiopia'), findsWidgets);

    expect(find.textContaining('mm'), findsWidgets);
  });
}
