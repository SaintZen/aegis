import 'package:anxiety_anchor/data/instrument_tour_copy.dart';
import 'package:anxiety_anchor/screens/instrument_tour_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget host({VoidCallback? onComplete}) {
    return MaterialApp(
      home: InstrumentTourScreen(
        onComplete: onComplete ?? () {},
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  test('copy lock: load-bearing Four Gates doctrine words are present', () {
    final fourGates = InstrumentTourCopy.stations
        .firstWhere((s) => s.id == 'four_gates');
    final blob = '${fourGates.name} ${fourGates.body}'.toLowerCase();
    for (final word in [
      'interceptor',
      'overload',
      'failure',
      'structurally possible',
      'imagination',
      'ledger',
    ]) {
      expect(blob, contains(word), reason: 'Four Gates station missing "$word"');
    }
  });

  test('copy lock: therapy verbs are absent', () {
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
    final blob = InstrumentTourCopy.allOperatorFacing.join('\n').toLowerCase();
    for (final word in forbidden) {
      expect(blob.contains(word), isFalse, reason: 'forbidden "$word" in tour copy');
    }
  });

  test('copy lock: station 1 BRIDGE names SCRAM as Priority 0', () {
    final bridge =
        InstrumentTourCopy.stations.firstWhere((s) => s.id == 'bridge');
    expect(bridge.body, contains('SCRAM'));
    expect(bridge.body.toLowerCase(), contains('priority 0'));
    expect(bridge.body.toLowerCase().contains('kill switch'), isFalse);
  });

  test('copy lock: the interrupt station is titled SCRAM, never Kill Switch', () {
    final scram =
        InstrumentTourCopy.stations.firstWhere((s) => s.id == 'scram');
    expect(scram.name, 'SCRAM');
    expect(scram.body.toLowerCase(), contains('priority 0'));
    expect(scram.body.toLowerCase(), contains('monolith'));
    final blob = InstrumentTourCopy.allOperatorFacing.join('\n').toLowerCase();
    expect(blob.contains('kill switch'), isFalse);
    expect(
      InstrumentTourCopy.stations.any((s) => s.name == 'KILL SWITCH'),
      isFalse,
    );
  });

  test('copy lock: Hollow is additive and Void is the only redact path', () {
    final hollow =
        InstrumentTourCopy.stations.firstWhere((s) => s.id == 'hollow');
    final voidStation =
        InstrumentTourCopy.stations.firstWhere((s) => s.id == 'void');
    expect(hollow.body.toLowerCase(), contains('additive'));
    expect(hollow.body, contains('verbatim'));
    expect(voidStation.body, contains('[REDACTED/PURGED]'));
    expect(voidStation.body, contains('CLEAR'));
  });

  test('hasCompleted is false until markCompleted', () async {
    expect(await InstrumentTourScreen.hasCompleted(), isFalse);
    await InstrumentTourScreen.markCompleted();
    expect(await InstrumentTourScreen.hasCompleted(), isTrue);
  });

  testWidgets('station 1 renders title, preamble, and SKIP is armed',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text(InstrumentTourCopy.title), findsOneWidget);
    expect(find.text(InstrumentTourCopy.preambleLine1), findsOneWidget);
    expect(find.text(InstrumentTourCopy.preambleLine2), findsOneWidget);
    expect(find.text('STATION 01 / 07'), findsOneWidget);
    expect(find.text('BRIDGE'), findsOneWidget);
    expect(find.text('KILL SWITCH'), findsNothing);
    expect(find.textContaining('SCRAM'), findsOneWidget);
    expect(find.text(InstrumentTourCopy.skipLabel), findsOneWidget);

    final skip = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, InstrumentTourCopy.skipLabel),
    );
    expect(skip.onPressed, isNotNull);
  });

  testWidgets('NEXT STATION advances; last station offers ENTER BRIDGE',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    for (var i = 0; i < InstrumentTourCopy.stations.length - 1; i++) {
      expect(find.text(InstrumentTourCopy.stations[i].name), findsOneWidget);
      expect(find.text(InstrumentTourCopy.nextLabel), findsOneWidget);
      await tester.tap(find.text(InstrumentTourCopy.nextLabel));
      await tester.pumpAndSettle();
    }

    expect(find.text(InstrumentTourCopy.stations.last.name), findsOneWidget);
    expect(find.text('SCRAM'), findsOneWidget);
    expect(find.text('STATION 07 / 07'), findsOneWidget);
    expect(find.text('KILL SWITCH'), findsNothing);
    expect(find.text(InstrumentTourCopy.enterLabel), findsOneWidget);
    expect(find.text(InstrumentTourCopy.nextLabel), findsNothing);
  });

  testWidgets('SKIP TOUR completes without visiting later stations',
      (tester) async {
    var completed = false;
    await tester.pumpWidget(host(onComplete: () => completed = true));
    await tester.pumpAndSettle();

    await tester.tap(find.text(InstrumentTourCopy.skipLabel));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(await InstrumentTourScreen.hasCompleted(), isTrue);
    expect(find.text('THE HOLLOW'), findsNothing);
  });

  testWidgets('ENTER BRIDGE completes after the last station', (tester) async {
    var completed = false;
    await tester.pumpWidget(host(onComplete: () => completed = true));
    await tester.pumpAndSettle();

    for (var i = 0; i < InstrumentTourCopy.stations.length - 1; i++) {
      await tester.tap(find.text(InstrumentTourCopy.nextLabel));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(InstrumentTourCopy.enterLabel));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(await InstrumentTourScreen.hasCompleted(), isTrue);
  });
}
