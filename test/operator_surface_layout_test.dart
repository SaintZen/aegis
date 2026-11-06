import 'package:anxiety_anchor/lifelines/not_today_screen.dart';
import 'package:anxiety_anchor/screens/calibration_screen.dart';
import 'package:anxiety_anchor/screens/hollow_screen.dart';
import 'package:anxiety_anchor/screens/safety_gate_screen.dart';
import 'package:anxiety_anchor/screens/worry_vault_screen.dart';
import 'package:anxiety_anchor/theme/aegis_hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('SECURE FOUNDATION fill is opaque over video bleed', () {
    expect(kSecureFoundationFill.a, greaterThanOrEqualTo(0.90));
  });

  testWidgets('Not Today titles sit below the AEGIS HUD reserve',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMaterialAppWithL10n(
      tester,
      home: const NotTodayScreen(),
    );

    final bar = tester.widget<PreferredSize>(
      find.byKey(const Key('aegis_hud_app_bar')),
    );
    expect(
      bar.preferredSize.height,
      kToolbarHeight + kAegisHudReserve,
    );

    expect(find.text('EXTERNAL LINKS'), findsOneWidget);
    expect(find.text('REFUSAL SCRIPTS'), findsWidgets);

    await tester.tap(find.text('HR / Insurance / Work templates'));
    await tester.pumpAndSettle();

    final refusal = tester.getRect(find.text('REFUSAL SCRIPTS').last);
    expect(refusal.top, greaterThan(kAegisHudReserve));
  });

  testWidgets('operational disclaimer names Aegis, not AnxietyAnchor',
      (tester) async {
    await pumpMaterialAppWithL10n(
      tester,
      home: SafetyGateScreen(onAccepted: () {}),
    );

    expect(find.textContaining('Aegis is for entertainment'), findsOneWidget);
    expect(find.textContaining('AnxietyAnchor'), findsNothing);
  });

  test('calibration disclaimer names Aegis, not AnxietyAnchor', () {
    expect(kAegisCalibrationDisclaimer.startsWith('Aegis '), isTrue);
    expect(kAegisCalibrationDisclaimer.contains('AnxietyAnchor'), isFalse);
    expect(kAegisOperationalDisclaimer.contains('AnxietyAnchor'), isFalse);
  });

  testWidgets('Hollow input uses a dark rounded well, not a square overlay',
      (tester) async {
    tester.view.physicalSize = const Size(800, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: HollowScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));

    final field = tester.widget<TextField>(find.byType(TextField));
    final decoration = field.decoration!;
    expect(decoration.fillColor!.a, greaterThanOrEqualTo(0.80));
    final border = decoration.border! as OutlineInputBorder;
    expect(border.borderRadius.topLeft.x, 8);
  });
}
