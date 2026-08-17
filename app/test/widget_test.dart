import 'package:flutter_test/flutter_test.dart';

import 'package:casa_oscar/main.dart';

void main() {
  testWidgets('CasaOscarApp arranca y muestra la marca', (WidgetTester tester) async {
    await tester.pumpWidget(const CasaOscarApp());
    await tester.pump();
    expect(find.text('Casa Oscar'), findsOneWidget);
  });
}
