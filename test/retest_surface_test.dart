import 'dart:math';

import 'package:anxiety_anchor/models/four_gates_run.dart';
import 'package:anxiety_anchor/models/pending_retest.dart';
import 'package:anxiety_anchor/screens/bridge_screen.dart';
import 'package:anxiety_anchor/screens/four_gates_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Surface tests for Phase 1.4-B (read-only).
///
/// These verify the badge and banner appear when the injected reader
/// reports due re-tests, and disappear cleanly when nothing is due.
/// They explicitly do NOT test execution/ratification — that's Phase
/// 1.4-C.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PendingRetest dueAt(DateTime runAt, {int seed = 0}) =>
      PendingRetest.forFailureRun(
        FourGatesRun(
          runAt: runAt,
          gates: const [
            GateResult(gate: FourGate.capacity, open: true, evidence: ''),
            GateResult(gate: FourGate.visibility, open: true, evidence: ''),
            GateResult(gate: FourGate.optionality, open: true, evidence: ''),
            GateResult(gate: FourGate.election, open: true, evidence: ''),
          ],
        ),
        random: Random(seed),
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget host(Widget child) =>
      MaterialApp(home: child, debugShowCheckedModeBanner: false);

  /// Bridge layout uses fixed-height regions that overflow the default
  /// 800x600 test viewport. Pump on a tall surface so we can assert the
  /// rendered widgets without RenderFlex overflows.
  Future<void> pumpBridgeTall(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  Future<void> noopLog({
    required String type,
    required String content,
  }) async {}

  Future<void> noopRecord(PendingRetest _) async {}

  group('Bridge tile [RETEST DUE] badge', () {
    testWidgets('hidden when no re-tests are due', (tester) async {
      await pumpBridgeTall(
        tester,
        host(BridgeScreen(
          dueRetestCount: ({required DateTime now}) async => 0,
        )),
      );
      expect(find.textContaining('RETEST DUE'), findsNothing);
    });

    testWidgets('shows [RETEST DUE] when exactly one is due', (tester) async {
      await pumpBridgeTall(
        tester,
        host(BridgeScreen(
          dueRetestCount: ({required DateTime now}) async => 1,
        )),
      );
      expect(find.text('[RETEST DUE]'), findsOneWidget);
    });

    testWidgets('shows count when more than one is due', (tester) async {
      await pumpBridgeTall(
        tester,
        host(BridgeScreen(
          dueRetestCount: ({required DateTime now}) async => 3,
        )),
      );
      expect(find.text('[RETEST DUE: 3]'), findsOneWidget);
    });

    testWidgets(
        'badge stays at zero when the reader throws (defense in depth)',
        (tester) async {
      await pumpBridgeTall(
        tester,
        host(BridgeScreen(
          dueRetestCount: ({required DateTime now}) async =>
              throw StateError('disk on fire'),
        )),
      );
      expect(find.text('FOUR GATES'), findsOneWidget);
      expect(find.textContaining('RETEST DUE'), findsNothing);
    });
  });

  group('FOUR GATES screen RE-TEST DUE banner', () {
    testWidgets('hidden when nothing is due', (tester) async {
      await tester.pumpWidget(host(FourGatesScreen(
        logLedgerEntry: noopLog,
        recordPendingRetest: noopRecord,
        loadDueRetests: ({required DateTime now}) async =>
            const <PendingRetest>[],
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('retest_due_banner')), findsNothing);
    });

    testWidgets('appears when exactly one re-test is due', (tester) async {
      final retest = dueAt(DateTime.utc(2026, 4, 25, 12), seed: 1);
      await tester.pumpWidget(host(FourGatesScreen(
        logLedgerEntry: noopLog,
        recordPendingRetest: noopRecord,
        loadDueRetests: ({required DateTime now}) async => [retest],
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('retest_due_banner')), findsOneWidget);
      expect(find.text('RE-TEST DUE'), findsOneWidget);
      expect(
        find.textContaining('awaiting ratification'),
        findsOneWidget,
      );
    });

    testWidgets('shows N PENDING when multiple are due', (tester) async {
      final earliest = dueAt(DateTime.utc(2026, 4, 24, 9), seed: 1);
      final later = dueAt(DateTime.utc(2026, 4, 25, 14), seed: 2);
      await tester.pumpWidget(host(FourGatesScreen(
        logLedgerEntry: noopLog,
        recordPendingRetest: noopRecord,
        loadDueRetests: ({required DateTime now}) async => [later, earliest],
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('retest_due_banner')), findsOneWidget);
      expect(find.text('RE-TEST DUE — 2 PENDING'), findsOneWidget);
      expect(
        find.textContaining('Earliest verdict'),
        findsOneWidget,
      );
    });

    testWidgets(
        'banner does not block the gate panel underneath '
        '(GATE 1 — CAPACITY still rendered)', (tester) async {
      final retest = dueAt(DateTime.utc(2026, 4, 25, 12), seed: 1);
      await tester.pumpWidget(host(FourGatesScreen(
        logLedgerEntry: noopLog,
        recordPendingRetest: noopRecord,
        loadDueRetests: ({required DateTime now}) async => [retest],
      )));
      await tester.pumpAndSettle();
      expect(find.text('GATE 1 — CAPACITY'), findsOneWidget);
      expect(find.byKey(const ValueKey('retest_due_banner')), findsOneWidget);
    });
  });
}
