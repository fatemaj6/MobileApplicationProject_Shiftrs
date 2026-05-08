import 'package:flutter_test/flutter_test.dart';
import 'package:careconnect/main.dart';

void main() {
  testWidgets('CareConnect app builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const CareConnectApp());
    expect(find.text('CareConnect'), findsOneWidget);
  });
}