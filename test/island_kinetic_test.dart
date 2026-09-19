import 'package:anxiety_anchor/screens/island_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('island audio silences on every non-resumed lifecycle state', () {
    expect(islandLifecycleSilencesAudio(AppLifecycleState.resumed), isFalse);
    expect(islandLifecycleSilencesAudio(AppLifecycleState.inactive), isTrue);
    expect(islandLifecycleSilencesAudio(AppLifecycleState.hidden), isTrue);
    expect(islandLifecycleSilencesAudio(AppLifecycleState.paused), isTrue);
    expect(islandLifecycleSilencesAudio(AppLifecycleState.detached), isTrue);
  });

  testWidgets('Kinetic Active launches the four Menu sequences', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: IslandScreen(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('KINETIC'));
    await tester.pump();

    expect(find.text('Wall Push'), findsOneWidget);
    expect(find.text('The Shake'), findsOneWidget);
    expect(find.text('Isometric'), findsOneWidget);
    expect(find.text('The Pulse'), findsOneWidget);
    expect(find.text('SELECT A SEQUENCE'), findsNothing);

    await tester.tap(find.text('ACTIVE'));
    await tester.pump();

    expect(find.text('SELECT A SEQUENCE'), findsOneWidget);
    expect(find.text('No active exercise running.'), findsNothing);
    expect(find.text('BACK TO MENU'), findsNothing);
    expect(find.text('Wall Push'), findsOneWidget);
    expect(find.text('The Shake'), findsOneWidget);
    expect(find.text('Isometric'), findsOneWidget);
    expect(find.text('The Pulse'), findsOneWidget);
  });

  testWidgets('Island lifecycle pause does not throw', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IslandScreen(),
      ),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.byType(IslandScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
