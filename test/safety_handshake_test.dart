import 'package:anxiety_anchor/data/safety_handshake_copy.dart';
import 'package:anxiety_anchor/screens/safety_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('handshake copy is the plain-English Not a Doctor gate', () {
    expect(SafetyHandshakeCopy.lineNotADoctor, 'Aegis is not a doctor.');
    expect(SafetyHandshakeCopy.title, 'SAFETY HANDSHAKE');
    expect(SafetyHandshakeCopy.enterLabel, 'ENTER');
  });

  test('handshake copy contains no therapy verbs', () {
    const forbidden = [
      'help',
      'feelings',
      'support',
      'cope',
      'comfort',
      'healing',
      'kindness',
      'self-care',
      'gentle',
      'soothe',
      'validate',
    ];
    final joined = SafetyHandshakeCopy.allOperatorFacing
        .join(' ')
        .toLowerCase();
    for (final word in forbidden) {
      expect(joined.contains(word), isFalse, reason: 'found "$word"');
    }
  });

  test('handshake copy does not use the retired AnxietyAnchor brand', () {
    final joined = SafetyHandshakeCopy.allOperatorFacing.join(' ');
    expect(joined.contains('AnxietyAnchor'), isFalse);
    expect(joined.toLowerCase().contains('anxiety anchor'), isFalse);
  });

  testWidgets('gate shows Not a Doctor copy and blocks ENTER until checked',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var accepted = false;
    await pumpMaterialAppWithL10n(
      tester,
      home: SafetyGateScreen(onAccepted: () => accepted = true),
    );
    await tester.pump();

    expect(find.text(SafetyHandshakeCopy.title), findsOneWidget);
    expect(find.text(SafetyHandshakeCopy.lineNotADoctor), findsWidgets);
    expect(find.text('AnxietyAnchor'), findsNothing);
    expect(find.text('Get Professional Help'), findsNothing);
    expect(find.text('Enter Lab'), findsNothing);
    expect(find.text(SafetyHandshakeCopy.crisisLinesLabel), findsOneWidget);

    final enter = find.byKey(const Key('safety-handshake-enter'));
    expect(tester.widget<ElevatedButton>(enter).onPressed, isNull);

    await tester.tap(find.byKey(const Key('safety-handshake-checkbox')));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(enter).onPressed, isNotNull);

    await tester.tap(enter);
    await tester.pumpAndSettle();

    expect(accepted, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SafetyGateScreen.prefsKey), isTrue);
  });

  testWidgets('hasAccepted reads the persisted handshake flag', (tester) async {
    expect(await SafetyGateScreen.hasAccepted(), isFalse);
    SharedPreferences.setMockInitialValues(
      <String, Object>{SafetyGateScreen.prefsKey: true},
    );
    expect(await SafetyGateScreen.hasAccepted(), isTrue);
  });
}
