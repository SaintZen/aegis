import 'package:anxiety_anchor/models/four_gates_run.dart';
import 'package:anxiety_anchor/models/pending_retest.dart';
import 'package:anxiety_anchor/screens/four_gates_screen.dart';
import 'package:anxiety_anchor/services/four_gates_vault.dart';
import 'package:anxiety_anchor/services/telemetry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // No-op stand-in for AegisLogService.logLedgerEntry. Used to keep
  // `_finalize` off the real path_provider channel (which hangs under
  // `flutter test`).
  Future<void> noopLog({
    required String type,
    required String content,
  }) async {}

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Telemetry.clear();
  });

  tearDown(() {
    Telemetry.clear();
  });

  Widget host(Widget child) =>
      MaterialApp(home: child, debugShowCheckedModeBanner: false);

  Future<void> chooseOpen(WidgetTester tester) async {
    await tester.tap(find.text('OPEN'));
    await tester.pump();
  }

  Future<void> chooseClosed(WidgetTester tester) async {
    await tester.tap(find.text('CLOSED'));
    await tester.pump();
  }

  Future<void> advance(WidgetTester tester) async {
    await tester.tap(find.text('NEXT GATE'));
    await tester.pumpAndSettle();
  }

  testWidgets('four OPEN gates classify the run as FAILURE and persist it',
      (tester) async {
    final vault = FourGatesVault();
    await tester.pumpWidget(host(FourGatesScreen(
      vault: vault,
      logLedgerEntry: noopLog,
    )));
    await tester.pumpAndSettle();

    expect(find.text('GATE 1 — CAPACITY'), findsOneWidget);
    await chooseOpen(tester);
    await advance(tester);

    expect(find.text('GATE 2 — VISIBILITY'), findsOneWidget);
    await chooseOpen(tester);
    await advance(tester);

    expect(find.text('GATE 3 — OPTIONALITY'), findsOneWidget);
    await chooseOpen(tester);
    await advance(tester);

    expect(find.text('GATE 4 — ELECTION'), findsOneWidget);
    await chooseOpen(tester);

    await tester.tap(find.text('RUN GATES'));
    await tester.pumpAndSettle();

    expect(find.text('STATUS: FAILURE'), findsOneWidget);
    expect(find.textContaining('CLASSIFICATION: FAILURE'), findsWidgets);
    expect(find.textContaining('NEXT: re-test in 24h.'), findsWidgets);

    final stored = await vault.load();
    expect(stored.length, 1);
    expect(stored.first.status, FourGatesStatus.failure);

    expect(
      Telemetry.events.any((e) =>
          e['event'] == 'four_gates_complete' &&
          (e['payload'] as Map)['status'] == 'failure'),
      isTrue,
    );
  });

  testWidgets('any CLOSED gate routes to OVERLOAD / NOT FAILURE',
      (tester) async {
    final vault = FourGatesVault();
    await tester.pumpWidget(host(FourGatesScreen(
      vault: vault,
      logLedgerEntry: noopLog,
    )));
    await tester.pumpAndSettle();

    await chooseOpen(tester);
    await advance(tester);
    await chooseClosed(tester); // visibility CLOSED
    await advance(tester);
    await chooseOpen(tester);
    await advance(tester);
    await chooseOpen(tester);

    await tester.tap(find.text('RUN GATES'));
    await tester.pumpAndSettle();

    expect(find.text('STATUS: OVERLOAD'), findsOneWidget);
    expect(find.textContaining('CLASSIFICATION: NOT FAILURE'), findsWidgets);
    expect(find.textContaining('NEXT: re-test in 24h.'), findsNothing);

    final stored = await vault.load();
    expect(stored.length, 1);
    expect(stored.first.status, FourGatesStatus.overload);
  });

  testWidgets('evidence text is preserved in the stored run and ledger',
      (tester) async {
    final vault = FourGatesVault();
    await tester.pumpWidget(host(FourGatesScreen(
      vault: vault,
      logLedgerEntry: noopLog,
    )));
    await tester.pumpAndSettle();

    await chooseOpen(tester);
    await tester.enterText(find.byType(TextField), 'had tools');
    await advance(tester);
    await chooseOpen(tester);
    await advance(tester);
    await chooseOpen(tester);
    await advance(tester);
    await chooseClosed(tester);
    await tester.enterText(find.byType(TextField), 'did not choose');

    await tester.tap(find.text('RUN GATES'));
    await tester.pumpAndSettle();

    final stored = await vault.load();
    expect(stored.first.gates.first.evidence, 'had tools');
    expect(stored.first.gates.last.evidence, 'did not choose');

    expect(find.textContaining('"had tools"'), findsWidgets);
    expect(find.textContaining('"did not choose"'), findsWidgets);
  });

  testWidgets('NEXT button is disabled until a decision is made',
      (tester) async {
    await tester.pumpWidget(host(const FourGatesScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('NEXT GATE'));
    await tester.pump();

    // Still on GATE 1 — nothing advanced because decision was null.
    expect(find.text('GATE 1 — CAPACITY'), findsOneWidget);
  });

  testWidgets(
      'finalize() forwards verbatim ledger body to AegisLogService '
      'as type=FOUR_GATES', (tester) async {
    final captured = <Map<String, String>>[];
    Future<void> fakeLog({required String type, required String content}) async {
      captured.add(<String, String>{'type': type, 'content': content});
    }

    final vault = FourGatesVault();
    await tester.pumpWidget(host(FourGatesScreen(
      vault: vault,
      logLedgerEntry: fakeLog,
    )));
    await tester.pumpAndSettle();

    await chooseOpen(tester);
    await advance(tester);
    await chooseOpen(tester);
    await advance(tester);
    await chooseOpen(tester);
    await advance(tester);
    await chooseOpen(tester);

    await tester.tap(find.text('RUN GATES'));
    await tester.pumpAndSettle();

    expect(captured, hasLength(1));
    expect(captured.single['type'], fourGatesLedgerType);
    expect(captured.single['type'], 'FOUR_GATES');

    final stored = await vault.load();
    expect(stored, hasLength(1));
    // Body must be the verbatim multi-line ledger output — NOT truncated.
    expect(captured.single['content'], stored.single.formatLedger());
    expect(captured.single['content'], contains('FOUR GATES'));
  });

  testWidgets('FAILURE verdict records a pending re-test contract',
      (tester) async {
    final captured = <PendingRetest>[];
    Future<void> recorder(PendingRetest r) async => captured.add(r);

    await tester.pumpWidget(host(FourGatesScreen(
      vault: FourGatesVault(),
      logLedgerEntry: noopLog,
      recordPendingRetest: recorder,
    )));
    await tester.pumpAndSettle();

    await chooseOpen(tester);
    await advance(tester);
    await chooseOpen(tester);
    await advance(tester);
    await chooseOpen(tester);
    await advance(tester);
    await chooseOpen(tester);
    await tester.tap(find.text('RUN GATES'));
    await tester.pumpAndSettle();

    expect(captured, hasLength(1));
    expect(captured.single.status, PendingRetestStatus.pending);
    expect(
      captured.single.dueAt,
      captured.single.originalRunAt.add(const Duration(hours: 24)),
    );
    expect(captured.single.id, startsWith('fgrt_'));

    expect(
      Telemetry.events.any((e) =>
          e['event'] == 'four_gates_pending_retest_recorded'),
      isTrue,
      reason: 'FAILURE verdicts must emit the pending-retest-recorded event',
    );
  });

  testWidgets(
      'OVERLOAD verdict does NOT record a pending re-test contract',
      (tester) async {
    final captured = <PendingRetest>[];
    Future<void> recorder(PendingRetest r) async => captured.add(r);

    await tester.pumpWidget(host(FourGatesScreen(
      vault: FourGatesVault(),
      logLedgerEntry: noopLog,
      recordPendingRetest: recorder,
    )));
    await tester.pumpAndSettle();

    await chooseClosed(tester); // any CLOSED gate forces OVERLOAD
    await advance(tester);
    await chooseOpen(tester);
    await advance(tester);
    await chooseOpen(tester);
    await advance(tester);
    await chooseOpen(tester);
    await tester.tap(find.text('RUN GATES'));
    await tester.pumpAndSettle();

    expect(
      captured,
      isEmpty,
      reason: 'OVERLOAD is the resolved state — no contract to write',
    );
    expect(
      Telemetry.events.any((e) =>
          e['event'] == 'four_gates_pending_retest_recorded'),
      isFalse,
    );
  });

  // ---------------------------------------------------------------
  // Operator-facing scaffolding (cursor rule §11):
  //   - micro-preamble appears ONLY on Gate 1, then disappears
  //   - micro-header appears under the gate name on every gate
  //   - copy on screen matches FourGate.microHeader 1:1
  // ---------------------------------------------------------------

  testWidgets(
      'micro-preamble renders on Gate 1 and disappears on Gate 2',
      (tester) async {
    await tester.pumpWidget(host(FourGatesScreen(
      vault: FourGatesVault(),
      logLedgerEntry: noopLog,
    )));
    await tester.pumpAndSettle();

    final preambleKey = find.byKey(const ValueKey('four_gates_micro_preamble'));
    expect(preambleKey, findsOneWidget,
        reason: 'preamble must render above Gate 1');
    expect(
      find.textContaining('two-second window'),
      findsOneWidget,
      reason: 'line 1 of the preamble must appear verbatim',
    );
    expect(
      find.textContaining('structurally possible'),
      findsOneWidget,
      reason: 'line 2 of the preamble must appear verbatim',
    );
    expect(
      find.textContaining('imagination cannot rewrite'),
      findsOneWidget,
      reason: 'line 3 of the preamble must appear verbatim',
    );

    await chooseOpen(tester);
    await advance(tester);

    expect(
      find.byKey(const ValueKey('four_gates_micro_preamble')),
      findsNothing,
      reason: 'preamble must disappear once the operator advances past Gate 1',
    );
    expect(find.text('GATE 2 — VISIBILITY'), findsOneWidget);
  });

  testWidgets(
      'each gate renders its locked micro-header below the gate name',
      (tester) async {
    await tester.pumpWidget(host(FourGatesScreen(
      vault: FourGatesVault(),
      logLedgerEntry: noopLog,
    )));
    await tester.pumpAndSettle();

    Future<void> expectHeaderFor(FourGate g) async {
      expect(
        find.byKey(ValueKey('gate_micro_header_${g.name}')),
        findsOneWidget,
        reason: 'micro-header for ${g.name} must be present on screen',
      );
      expect(
        find.text(g.microHeader),
        findsOneWidget,
        reason: 'micro-header copy for ${g.name} must match the model',
      );
    }

    await expectHeaderFor(FourGate.capacity);
    await chooseOpen(tester);
    await advance(tester);
    await expectHeaderFor(FourGate.visibility);
    await chooseOpen(tester);
    await advance(tester);
    await expectHeaderFor(FourGate.optionality);
    await chooseOpen(tester);
    await advance(tester);
    await expectHeaderFor(FourGate.election);
  });

  test('FourGatesVault keeps only the last 5 runs, newest first', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestWidgetsFlutterBinding.ensureInitialized();
    // Ensure MethodChannel Clipboard stays quiet during headless test.
    SystemChannels.platform.setMockMethodCallHandler((_) async => null);

    final vault = FourGatesVault();
    final base = DateTime.utc(2026, 4, 18, 12);
    for (var i = 0; i < 7; i++) {
      await vault.append(FourGatesRun(
        runAt: base.add(Duration(minutes: i)),
        gates: [
          GateResult(gate: FourGate.capacity, open: true, evidence: 'r$i'),
          const GateResult(
              gate: FourGate.visibility, open: true, evidence: ''),
          const GateResult(
              gate: FourGate.optionality, open: true, evidence: ''),
          const GateResult(
              gate: FourGate.election, open: true, evidence: ''),
        ],
      ));
    }

    final stored = await vault.load();
    expect(stored.length, 5);
    expect(stored.first.gates.first.evidence, 'r6');
    expect(stored.last.gates.first.evidence, 'r2');
  });
}
