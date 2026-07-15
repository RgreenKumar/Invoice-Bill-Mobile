import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_bill/main.dart';

void main() {
  testWidgets('InvoiceBillApp mounts smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const InvoiceBillApp());

    // Verify that our auth container has booted and shows the login view
    expect(find.text('Sign In'), findsOneWidget);
  });
}
