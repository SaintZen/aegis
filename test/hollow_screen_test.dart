import 'package:anxiety_anchor/screens/hollow_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
      'landscape: stone definition hides when the 7th-sense field is focused',
      (tester) async {
    tester.view.physicalSize = const Size(800, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: HollowScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('ENTER THE WELL'), findsOneWidget);

    // Skip the 5s countdown. Periodic ripple/repaint timers forbid pumpAndSettle.
    await tester.pump(const Duration(seconds: 6));

    expect(find.text('THE HOLLOW'), findsOneWidget);
    expect(find.text('Triggered'), findsOneWidget);

    await tester.tap(find.text('Triggered'));
    await tester.pump();

    expect(
      find.text('Something in the present echoed an old pattern.'),
      findsOneWidget,
    );
    expect(find.text('Reset the Well'), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(
      find.text('Something in the present echoed an old pattern.'),
      findsNothing,
    );
    expect(find.text('Reset the Well'), findsNothing);
  });
}
