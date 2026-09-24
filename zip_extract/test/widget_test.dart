import 'package:flutter_test/flutter_test.dart';

import 'package:phud_box/main.dart';

void main() {
  testWidgets('app loads the device scan screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PhudBoxApp());

    expect(find.text('CONNECT DEVICE'), findsOneWidget);
    expect(find.text('Scan for PHUD Box Devices'), findsOneWidget);
  });
}
