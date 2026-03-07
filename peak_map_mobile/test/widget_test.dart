import 'package:flutter_test/flutter_test.dart';

import 'package:peak_map_mobile/main.dart';

void main() {
  testWidgets('Home screen renders role selection', (WidgetTester tester) async {
    await tester.pumpWidget(const PeakMapApp());

    expect(find.text('PEAK MAP'), findsOneWidget);
    expect(find.text("I'm a Driver"), findsOneWidget);
    expect(find.text("I'm a Passenger"), findsOneWidget);
  });
}
