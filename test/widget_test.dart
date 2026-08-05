import 'package:flutter_test/flutter_test.dart';
import 'package:motogate_app/main.dart';

void main() {
  testWidgets('App launches and shows splash', (WidgetTester tester) async {
    await tester.pumpWidget(const MotoGateApp());

    // Splash shows app name
    expect(find.text('MotoGate'), findsOneWidget);

    // Advance past splash delay to avoid pending timers and allow navigation
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
