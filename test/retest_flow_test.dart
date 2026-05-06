import 'package:anxiety_anchor/models/four_gates_run.dart';
import 'package:anxiety_anchor/models/pending_retest.dart';
import 'package:anxiety_anchor/screens/four_gates_screen.dart';
import 'package:anxiety_anchor/services/four_gates_vault.dart';
import 'package:anxiety_anchor/services/telemetry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Re-test flow tests (Phase 1.4-C-2).
///
/// Covers:
///   - Banner RUN RE-TEST button enters re-test mode
///   - Re-test FAILURE → audit log gets `[RE-TEST OF ...] CONFIRMED` header
///   - Re-test OVERLOAD → audit log gets `[RE-TEST OF ...] OVERTURNED` header
///   - Re-test FAILURE chains a NEW pending contract (Q6: A)
///   - Re-test OVERLOAD does NOT chain
///   - Original evidence is blind by default; REVEAL ORIGINAL toggle
///   - Contract is mutated (ratified) via updatePendingRetest hook
///   - Result panel shows the ratification banner with the verdict header
void main() {
  Future<void> noopLog({
    required String type,
    required String content,
  }) async {}

  Future<void> noopRecord(PendingRetest _) async {}

  PendingRetest dueFailureContract({
    String evidence = 'orig-evidence',
    DateTime? originalRunAt,
  }) {
    final at = originalRunAt ?? DateTime.utc(2026, 4, 25, 12);
    final run = FourGatesRun(
      runAt: at,
      gates: [
        GateResult(gate: FourGate.capacity, open: true, evidence: evidence),
        GateResult(gate: FourGate.visibility, open: true, evidence: 'v'),
        GateResult(gate: FourGate.optionality, open: true, evidence: 'o'),
        GateResult(gate: FourGate.election, open: true, evidence: 'e'),
      ],
    );
    return PendingRetest.forFailureRun(run);
  }

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

  group('Re-test flow — entry from banner', () {
    testWidgets('tapping RUN RE-TEST enters re-test mode (header visible)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = dueFailureContract();
      await tester.pumpWidget(host(FourGatesScreen(
        vault: FourGatesVault(),
        logLedgerEntry: noopLog,
        recordPendingRetest: noopRecord,
        updatePendingRetest: noopRecord,
        loadDueRetests: ({required DateTime now}) async => <PendingRetest>[
          contract,
        ],
      )));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('retest_due_banner')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('retest_due_banner_run_button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('retest_due_banner_run_button')),
      );
      await tester.pumpAndSettle();

      // Banner replaced by the in-flight re-test header.
      expect(find.byKey(const ValueKey('retest_header')), findsOneWidget);
      // The standing banner is suppressed once a re-test is in progress.
      expect(
        find.byKey(const ValueKey('retest_due_banner')),
        findsNothing,
      );
      // Telemetry recorded the entry.
      expect(
        Telemetry.events.any((e) => e['event'] == 'four_gates_retest_started'),
        isTrue,
      );
    });
  });

  group('Re-test flow — REVEAL ORIGINAL', () {
    testWidgets('original evidence is blind by default and shown on tap',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = dueFailureContract(evidence: 'i was overloaded');
      await tester.pumpWidget(host(FourGatesScreen(
        vault: FourGatesVault(),
        logLedgerEntry: noopLog,
        recordPendingRetest: noopRecord,
        updatePendingRetest: noopRecord,
        loadDueRetests: ({required DateTime now}) async => <PendingRetest>[
          contract,
        ],
      )));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('retest_due_banner_run_button')),
      );
      await tester.pumpAndSettle();

      // Reveal button visible; original text NOT visible yet.
      expect(
        find.byKey(const ValueKey('reveal_original_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('original_evidence_text')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('reveal_original_button')));
      await tester.pumpAndSettle();

      // Original evidence now revealed.
      expect(
        find.byKey(const ValueKey('original_evidence_text')),
        findsOneWidget,
      );
      expect(find.textContaining('i was overloaded'), findsOneWidget);
    });
  });

  group('Re-test flow — finalize / ratification', () {
    testWidgets(
        'FAILURE re-test → audit body has CONFIRMED header + chains '
        'a new pending contract', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = dueFailureContract();
      final loggedBodies = <String>[];
      Future<void> capturingLog({
        required String type,
        required String content,
      }) async {
        loggedBodies.add(content);
      }

      final newContracts = <PendingRetest>[];
      Future<void> capturingRecord(PendingRetest r) async {
        newContracts.add(r);
      }

      final updated = <PendingRetest>[];
      Future<void> capturingUpdate(PendingRetest r) async {
        updated.add(r);
      }

      await tester.pumpWidget(host(FourGatesScreen(
        vault: FourGatesVault(),
        logLedgerEntry: capturingLog,
        recordPendingRetest: capturingRecord,
        updatePendingRetest: capturingUpdate,
        loadDueRetests: ({required DateTime now}) async => <PendingRetest>[
          contract,
        ],
      )));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('retest_due_banner_run_button')),
      );
      await tester.pumpAndSettle();

      // Re-test produces FAILURE: all four OPEN.
      await chooseOpen(tester);
      await advance(tester);
      await chooseOpen(tester);
      await advance(tester);
      await chooseOpen(tester);
      await advance(tester);
      await chooseOpen(tester);
      await tester.tap(find.text('RUN RE-TEST'));
      await tester.pumpAndSettle();

      // Audit body wears the CONFIRMED header and references the original id.
      expect(loggedBodies, hasLength(1));
      expect(
        loggedBodies.single,
        startsWith('[RE-TEST OF ${contract.id}] CONFIRMED\n'),
      );
      expect(loggedBodies.single, contains('FOUR GATES'));
      expect(loggedBodies.single, contains('STATUS:         FAILURE'));

      // Contract was mutated: status became ratifiedConfirmed.
      expect(updated, hasLength(1));
      expect(updated.single.id, contract.id);
      expect(updated.single.status, PendingRetestStatus.ratifiedConfirmed);
      expect(updated.single.ratifiedAt, isNotNull);
      expect(updated.single.ratifyingRunAt, isNotNull);

      // Q6: A — chained. Re-test FAILURE creates a NEW pending contract
      // for the new run.
      expect(newContracts, hasLength(1));
      expect(newContracts.single.status, PendingRetestStatus.pending);
      expect(newContracts.single.id, isNot(contract.id));

      // Result panel shows the ratification banner with the header.
      expect(
        find.byKey(const ValueKey('four_gates_ratification_banner')),
        findsOneWidget,
      );
      expect(
        find.text('[RE-TEST OF ${contract.id}] CONFIRMED'),
        findsOneWidget,
      );

      // Telemetry: ratified + chained-from event. (Telemetry events are
      // `{event: name, payload: {...}}` — payload holds keyed values.)
      final ratified = Telemetry.events.firstWhere(
        (e) => e['event'] == 'four_gates_retest_ratified',
        orElse: () => const <String, dynamic>{'payload': <String, dynamic>{}},
      );
      final ratifiedPayload =
          (ratified['payload'] as Map<String, dynamic>);
      expect(ratifiedPayload['verdict'], 'CONFIRMED');
      expect(ratifiedPayload['original_id'], contract.id);

      final chained = Telemetry.events.firstWhere(
        (e) {
          if (e['event'] != 'four_gates_pending_retest_recorded') return false;
          final payload = e['payload'] as Map<String, dynamic>?;
          return payload != null && payload['chained_from'] == contract.id;
        },
        orElse: () => const <String, dynamic>{'payload': <String, dynamic>{}},
      );
      final chainedPayload =
          (chained['payload'] as Map<String, dynamic>);
      expect(chainedPayload['chained_from'], contract.id);
    });

    testWidgets(
        'OVERLOAD re-test → audit body has OVERTURNED header and '
        'no new contract is chained', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = dueFailureContract();
      final loggedBodies = <String>[];
      Future<void> capturingLog({
        required String type,
        required String content,
      }) async {
        loggedBodies.add(content);
      }

      final newContracts = <PendingRetest>[];
      Future<void> capturingRecord(PendingRetest r) async {
        newContracts.add(r);
      }

      final updated = <PendingRetest>[];
      Future<void> capturingUpdate(PendingRetest r) async {
        updated.add(r);
      }

      await tester.pumpWidget(host(FourGatesScreen(
        vault: FourGatesVault(),
        logLedgerEntry: capturingLog,
        recordPendingRetest: capturingRecord,
        updatePendingRetest: capturingUpdate,
        loadDueRetests: ({required DateTime now}) async => <PendingRetest>[
          contract,
        ],
      )));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('retest_due_banner_run_button')),
      );
      await tester.pumpAndSettle();

      // Re-test produces OVERLOAD: any CLOSED forces it.
      await chooseClosed(tester);
      await advance(tester);
      await chooseOpen(tester);
      await advance(tester);
      await chooseOpen(tester);
      await advance(tester);
      await chooseOpen(tester);
      await tester.tap(find.text('RUN RE-TEST'));
      await tester.pumpAndSettle();

      expect(loggedBodies, hasLength(1));
      expect(
        loggedBodies.single,
        startsWith('[RE-TEST OF ${contract.id}] OVERTURNED\n'),
      );
      expect(loggedBodies.single, contains('STATUS:         OVERLOAD'));

      expect(updated, hasLength(1));
      expect(updated.single.status, PendingRetestStatus.ratifiedOverturned);

      // OVERLOAD on a re-test ends the chain — no new contract.
      expect(
        newContracts,
        isEmpty,
        reason: 'OVERLOAD on re-test ends the chain (Q6: A interpretation)',
      );
    });
  });
}
