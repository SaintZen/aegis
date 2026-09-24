import 'package:anxiety_anchor/screens/island_screen.dart';
import 'package:anxiety_anchor/scripts/kinetic_scripts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('vibration'),
      (call) async {
        if (call.method == 'hasVibrator') return false;
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  test('island audio silences on every non-resumed lifecycle state', () {
    expect(islandLifecycleSilencesAudio(AppLifecycleState.resumed), isFalse);
    expect(islandLifecycleSilencesAudio(AppLifecycleState.inactive), isTrue);
    expect(islandLifecycleSilencesAudio(AppLifecycleState.hidden), isTrue);
    expect(islandLifecycleSilencesAudio(AppLifecycleState.paused), isTrue);
    expect(islandLifecycleSilencesAudio(AppLifecycleState.detached), isTrue);
  });

  testWidgets('Kinetic Active launches the four Menu sequences', (tester) async {
    tester.view.physicalSize = const Size(390, 1800);
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
    expect(find.byKey(const Key('kinetic_override')), findsOneWidget);
    expect(find.text('[ OVERRIDE ]'), findsOneWidget);
    expect(find.text('HOT CAR'), findsOneWidget);
    expect(find.text('WINTER'), findsOneWidget);
    expect(find.text('HEATWAVE'), findsOneWidget);
    expect(find.text('STALL'), findsOneWidget);
    expect(find.text('HEADPHONES'), findsOneWidget);
    expect(find.text('SINK'), findsOneWidget);
    expect(
      find.text('Phone on the thigh. Read the card. Hands off the wheel.'),
      findsOneWidget,
    );

    final headphones = find.byKey(const Key('kinetic_field_headphones_dark'));
    await tester.ensureVisible(headphones);
    await tester.tap(headphones);
    await tester.pump();
    expect(find.textContaining('Cover the eyes'), findsOneWidget);
    expect(find.textContaining('Cut incoming voice'), findsOneWidget);
    expect(find.byKey(const Key('kinetic_swap')), findsNothing);

    final hotCar = find.byKey(const Key('kinetic_field_hot_car'));
    await tester.ensureVisible(hotCar);
    await tester.tap(hotCar);
    await tester.pump();
    expect(find.textContaining('Grip the seat edge'), findsOneWidget);
    expect(find.textContaining('clench the wheel'), findsNothing);
    expect(find.textContaining('Cover the eyes'), findsNothing);
    expect(find.text('LOW SIG'), findsOneWidget);
    expect(find.text('POOR MAN'), findsNothing);
    expect(find.text('No instrument. Bus or meeting. Phone stays down.'), findsOneWidget);
    expect(find.byKey(const Key('kinetic_low_sig_draw')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('kinetic_low_sig_draw')));
    await tester.tap(find.byKey(const Key('kinetic_low_sig_draw')));
    await tester.pump();
    expect(
      kineticStealthDeck.where(
        (script) => find.text(script.instructions).evaluate().isNotEmpty,
      ),
      hasLength(1),
    );
    expect(find.byKey(const Key('kinetic_swap')), findsNothing);
    await tester.ensureVisible(find.text('LOBE'));
    expect(find.text('LOBE'), findsOneWidget);
    expect(find.text('TOES'), findsOneWidget);
    expect(find.text('JAW'), findsOneWidget);
    expect(find.text('FIST'), findsOneWidget);
    expect(find.text('HEEL'), findsOneWidget);
    expect(find.text('THUMB'), findsOneWidget);

    // DRAW expands one random LOW SIG card. LOBE tap toggles; if DRAW
    // already landed on LOBE, a second tap collapses the instructions.
    final lobeRow = find.byKey(const Key('kinetic_stealth_stealth_lobe'));
    await tester.ensureVisible(lobeRow);
    if (find.textContaining('Left earlobe').evaluate().isEmpty) {
      await tester.tap(lobeRow);
      await tester.pump();
    }
    expect(find.textContaining('Left earlobe'), findsOneWidget);
    expect(find.byKey(const Key('kinetic_swap')), findsNothing);

    await tester.tap(find.text('ACTIVE'));
    await tester.pump();

    expect(find.text('SELECT A SEQUENCE'), findsOneWidget);
    expect(find.text('No active exercise running.'), findsNothing);
    expect(find.text('BACK TO MENU'), findsNothing);
    expect(find.text('Wall Push'), findsOneWidget);
    expect(find.text('The Shake'), findsOneWidget);
    expect(find.text('Isometric'), findsOneWidget);
    expect(find.text('The Pulse'), findsOneWidget);
    expect(find.byKey(const Key('kinetic_override')), findsOneWidget);
    expect(find.text('HOT CAR'), findsOneWidget);
  });

  testWidgets('OVERRIDE fires an instrument and exposes SWAP', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
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
    await tester.ensureVisible(find.byKey(const Key('kinetic_override')));
    await tester.tap(find.byKey(const Key('kinetic_override')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('kinetic_swap')), findsOneWidget);
    expect(find.text('SWAP'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 8));
  });

  testWidgets('landscape Vista pages swipe; dots remain', (tester) async {
    tester.view.physicalSize = const Size(800, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: IslandScreen(),
      ),
    );
    await tester.pump();

    final pager = find.byKey(const ValueKey('vista_landscape_pager'));
    expect(pager, findsOneWidget);

    await tester.drag(pager, const Offset(-400, 0));
    await tester.pump();

    expect(pager, findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Container) return false;
        if (widget.margin != const EdgeInsets.symmetric(horizontal: 6)) {
          return false;
        }
        final decoration = widget.decoration;
        return decoration is BoxDecoration && decoration.shape == BoxShape.circle;
      }),
      findsNWidgets(3),
    );
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
