import 'package:flutter_test/flutter_test.dart';
import 'package:my/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyLedgerApp());

    // Verify that the login screen is shown
    expect(find.text('My Ledger'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
