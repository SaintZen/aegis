import 'package:anxiety_anchor/models/four_gates_run.dart';
import 'package:anxiety_anchor/models/pending_retest.dart';
import 'package:anxiety_anchor/services/pdf_generator_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the FOUR GATES strata bucketer in `PdfGeneratorService`.
///
/// These tests guard the coupling between
/// `FourGatesRun.formatLedger()` (the format we emit into the audit log)
/// and `PdfGeneratorService._classifyFourGatesContent` (the regex we use
/// to read it back when rendering the PDF strata table). If either side
/// drifts, the bucket counts go wrong silently — these tests fire first.
void main() {
  group('debugClassifyFourGatesContent', () {
    test('classifies an OVERLOAD run produced by formatLedger()', () {
      final run = FourGatesRun(
        runAt: DateTime.utc(2026, 4, 20, 12),
        gates: const [
          GateResult(gate: FourGate.capacity, open: true, evidence: ''),
          GateResult(gate: FourGate.visibility, open: false, evidence: ''),
          GateResult(gate: FourGate.optionality, open: true, evidence: ''),
          GateResult(gate: FourGate.election, open: true, evidence: ''),
        ],
      );
      expect(
        PdfGeneratorService.debugClassifyFourGatesContent(run.formatLedger()),
        'OVERLOAD',
      );
    });

    test('classifies a FAILURE run produced by formatLedger()', () {
      final run = FourGatesRun(
        runAt: DateTime.utc(2026, 4, 20, 12),
        gates: const [
          GateResult(gate: FourGate.capacity, open: true, evidence: ''),
          GateResult(gate: FourGate.visibility, open: true, evidence: ''),
          GateResult(gate: FourGate.optionality, open: true, evidence: ''),
          GateResult(gate: FourGate.election, open: true, evidence: ''),
        ],
      );
      expect(
        PdfGeneratorService.debugClassifyFourGatesContent(run.formatLedger()),
        'FAILURE',
      );
    });

    test('returns null for malformed / legacy content', () {
      expect(
        PdfGeneratorService.debugClassifyFourGatesContent('totally unrelated'),
        isNull,
      );
      expect(
        PdfGeneratorService.debugClassifyFourGatesContent(''),
        isNull,
      );
      expect(
        PdfGeneratorService.debugClassifyFourGatesContent('STATUS: UNKNOWN'),
        isNull,
      );
    });
  });

  group('debugBucketFourGatesByWeek', () {
    String overloadLedger() => FourGatesRun(
          runAt: DateTime.utc(2026, 4, 20),
          gates: const [
            GateResult(gate: FourGate.capacity, open: false, evidence: ''),
            GateResult(gate: FourGate.visibility, open: true, evidence: ''),
            GateResult(gate: FourGate.optionality, open: true, evidence: ''),
            GateResult(gate: FourGate.election, open: true, evidence: ''),
          ],
        ).formatLedger();

    String failureLedger() => FourGatesRun(
          runAt: DateTime.utc(2026, 4, 20),
          gates: const [
            GateResult(gate: FourGate.capacity, open: true, evidence: ''),
            GateResult(gate: FourGate.visibility, open: true, evidence: ''),
            GateResult(gate: FourGate.optionality, open: true, evidence: ''),
            GateResult(gate: FourGate.election, open: true, evidence: ''),
          ],
        ).formatLedger();

    test('groups runs into Monday-anchored weeks, newest first', () {
      // 2026-04-20 is a Monday. 2026-04-22 is a Wednesday in the same week.
      // 2026-04-13 is the previous Monday.
      final rows = PdfGeneratorService.debugBucketFourGatesByWeek(
        <DateTime>[
          DateTime(2026, 4, 20, 9),
          DateTime(2026, 4, 22, 14),
          DateTime(2026, 4, 22, 16),
          DateTime(2026, 4, 13, 11),
        ],
        <String>[
          overloadLedger(),
          overloadLedger(),
          failureLedger(),
          overloadLedger(),
        ],
      );

      expect(rows, hasLength(2));
      expect(rows.first['weekStart'], DateTime(2026, 4, 20));
      expect(rows.first['overload'], 2);
      expect(rows.first['failure'], 1);
      expect(rows.last['weekStart'], DateTime(2026, 4, 13));
      expect(rows.last['overload'], 1);
      expect(rows.last['failure'], 0);
    });

    test('a Sunday is bucketed into the PRIOR week (Mon-Sun)', () {
      // 2026-04-19 is the Sunday of the week starting Mon 2026-04-13.
      final rows = PdfGeneratorService.debugBucketFourGatesByWeek(
        <DateTime>[DateTime(2026, 4, 19, 23, 30)],
        <String>[overloadLedger()],
      );
      expect(rows, hasLength(1));
      expect(rows.single['weekStart'], DateTime(2026, 4, 13));
      expect(rows.single['overload'], 1);
    });

    test('unclassifiable bodies are excluded from counts entirely', () {
      final rows = PdfGeneratorService.debugBucketFourGatesByWeek(
        <DateTime>[
          DateTime(2026, 4, 20, 9),
          DateTime(2026, 4, 20, 9),
        ],
        <String>['garbage', overloadLedger()],
      );
      expect(rows, hasLength(1));
      expect(rows.single['overload'], 1);
      expect(rows.single['failure'], 0);
    });

    test('empty input returns an empty list', () {
      final rows = PdfGeneratorService.debugBucketFourGatesByWeek(
        const <DateTime>[],
        const <String>[],
      );
      expect(rows, isEmpty);
    });
  });

  // Phase 1.4-C-3: RATIFIED column on the strata table.
  group('debugBucketFourGatesByWeek — RATIFIED column', () {
    String failureLedger() => FourGatesRun(
          runAt: DateTime.utc(2026, 4, 20),
          gates: const [
            GateResult(gate: FourGate.capacity, open: true, evidence: ''),
            GateResult(gate: FourGate.visibility, open: true, evidence: ''),
            GateResult(gate: FourGate.optionality, open: true, evidence: ''),
            GateResult(gate: FourGate.election, open: true, evidence: ''),
          ],
        ).formatLedger();

    PendingRetest ratifiedFailureContractFor(DateTime originalRunAt) {
      final original = FourGatesRun(
        runAt: originalRunAt,
        gates: const [
          GateResult(gate: FourGate.capacity, open: true, evidence: 'a'),
          GateResult(gate: FourGate.visibility, open: true, evidence: 'b'),
          GateResult(gate: FourGate.optionality, open: true, evidence: 'c'),
          GateResult(gate: FourGate.election, open: true, evidence: 'd'),
        ],
      );
      final retest = FourGatesRun(
        runAt: originalRunAt.add(const Duration(hours: 25)),
        gates: const [
          GateResult(gate: FourGate.capacity, open: false, evidence: 'a'),
          GateResult(gate: FourGate.visibility, open: true, evidence: 'b'),
          GateResult(gate: FourGate.optionality, open: true, evidence: 'c'),
          GateResult(gate: FourGate.election, open: true, evidence: 'd'),
        ],
      );
      return PendingRetest.forFailureRun(original).ratify(
        retestRun: retest,
        at: originalRunAt.add(const Duration(hours: 25)),
      );
    }

    test('RATIFIED count is attributed to the ORIGINAL FAILURE\'s week',
        () {
      // Original FAILURE on Mon 2026-04-13. Re-test 25h later (week of
      // Mon 2026-04-20). RATIFIED count must land on 2026-04-13.
      final originalAt = DateTime.utc(2026, 4, 13, 9);
      final ratified = ratifiedFailureContractFor(originalAt);

      final rows = PdfGeneratorService.debugBucketFourGatesByWeek(
        <DateTime>[originalAt],
        <String>[failureLedger()],
        ratifiedRetests: [ratified],
      );

      expect(rows, hasLength(1));
      expect(rows.single['weekStart'], DateTime(2026, 4, 13));
      expect(rows.single['failure'], 1);
      expect(rows.single['ratified'], 1);
      expect(rows.single['overload'], 0);
    });

    test('a ratification with no FAILURE entry in the same week still '
        'creates a row with RATIFIED=1', () {
      final originalAt = DateTime.utc(2026, 4, 13, 9);
      final ratified = ratifiedFailureContractFor(originalAt);

      final rows = PdfGeneratorService.debugBucketFourGatesByWeek(
        const <DateTime>[],
        const <String>[],
        ratifiedRetests: [ratified],
      );
      expect(rows, hasLength(1));
      expect(rows.single['weekStart'], DateTime(2026, 4, 13));
      expect(rows.single['failure'], 0);
      expect(rows.single['ratified'], 1);
    });

    test('re-test ledger entries are excluded from FAILURE / OVERLOAD '
        'counts (no double counting)', () {
      // The ratifying re-test gets its own audit entry whose body
      // starts with `[RE-TEST OF ...]`. That body must NOT be counted
      // as a fresh FAILURE.
      final originalAt = DateTime.utc(2026, 4, 13, 9);
      final ratifyingAt = originalAt.add(const Duration(hours: 25));
      final ratifiedContract = ratifiedFailureContractFor(originalAt);

      final retestBody =
          '[RE-TEST OF ${ratifiedContract.id}] OVERTURNED\n'
          '${FourGatesRun(
        runAt: ratifyingAt,
        gates: const [
          GateResult(gate: FourGate.capacity, open: false, evidence: ''),
          GateResult(gate: FourGate.visibility, open: true, evidence: ''),
          GateResult(gate: FourGate.optionality, open: true, evidence: ''),
          GateResult(gate: FourGate.election, open: true, evidence: ''),
        ],
      ).formatLedger()}';

      final rows = PdfGeneratorService.debugBucketFourGatesByWeek(
        <DateTime>[originalAt, ratifyingAt],
        <String>[failureLedger(), retestBody],
        ratifiedRetests: [ratifiedContract],
      );

      // Two rows: one for the original week (Mon 2026-04-13) and one
      // for the re-test week (Mon 2026-04-20). The re-test week is
      // EMPTY of failure/overload counts because ratifications don't
      // get fresh-verdict counts.
      final originalWeek = rows.firstWhere(
        (r) => r['weekStart'] == DateTime(2026, 4, 13),
      );
      expect(originalWeek['failure'], 1);
      expect(originalWeek['overload'], 0);
      expect(originalWeek['ratified'], 1);

      final hasRetestWeek = rows.any(
        (r) => r['weekStart'] == DateTime(2026, 4, 20),
      );
      // The re-test week should NOT show fresh failures or overloads.
      if (hasRetestWeek) {
        final retestWeek = rows.firstWhere(
          (r) => r['weekStart'] == DateTime(2026, 4, 20),
        );
        expect(retestWeek['failure'], 0);
        expect(retestWeek['overload'], 0);
      }
    });
  });

  // Phase 1.4-C-3: RATIFICATION RECORDS section.
  group('debugBuildRatificationRows', () {
    PendingRetest contract({
      required String idSuffix,
      required DateTime originalRunAt,
      required PendingRetestStatus terminal,
      required DateTime ratifiedAt,
    }) {
      final original = FourGatesRun(
        runAt: originalRunAt,
        gates: const [
          GateResult(gate: FourGate.capacity, open: true, evidence: ''),
          GateResult(gate: FourGate.visibility, open: true, evidence: ''),
          GateResult(gate: FourGate.optionality, open: true, evidence: ''),
          GateResult(gate: FourGate.election, open: true, evidence: ''),
        ],
      );
      final retestGates = terminal == PendingRetestStatus.ratifiedConfirmed
          ? const [
              GateResult(gate: FourGate.capacity, open: true, evidence: ''),
              GateResult(gate: FourGate.visibility, open: true, evidence: ''),
              GateResult(gate: FourGate.optionality, open: true, evidence: ''),
              GateResult(gate: FourGate.election, open: true, evidence: ''),
            ]
          : const [
              GateResult(gate: FourGate.capacity, open: false, evidence: ''),
              GateResult(gate: FourGate.visibility, open: true, evidence: ''),
              GateResult(gate: FourGate.optionality, open: true, evidence: ''),
              GateResult(gate: FourGate.election, open: true, evidence: ''),
            ];
      final retest = FourGatesRun(
        runAt: ratifiedAt,
        gates: retestGates,
      );
      // Override the contract's id for deterministic row assertions.
      final raw = PendingRetest.forFailureRun(original);
      return PendingRetest(
        id: 'fgrt_test_$idSuffix',
        originalRunAt: raw.originalRunAt,
        dueAt: raw.dueAt,
        originalGates: raw.originalGates,
      ).ratify(retestRun: retest, at: ratifiedAt);
    }

    test('only ratified contracts appear; pending are skipped', () {
      final pending = PendingRetest.forFailureRun(FourGatesRun(
        runAt: DateTime.utc(2026, 4, 25),
        gates: const [
          GateResult(gate: FourGate.capacity, open: true, evidence: ''),
          GateResult(gate: FourGate.visibility, open: true, evidence: ''),
          GateResult(gate: FourGate.optionality, open: true, evidence: ''),
          GateResult(gate: FourGate.election, open: true, evidence: ''),
        ],
      ));
      final ratified = contract(
        idSuffix: 'a',
        originalRunAt: DateTime.utc(2026, 4, 24),
        terminal: PendingRetestStatus.ratifiedConfirmed,
        ratifiedAt: DateTime.utc(2026, 4, 25, 13),
      );
      final rows = PdfGeneratorService.debugBuildRatificationRows([
        pending,
        ratified,
      ]);
      expect(rows, hasLength(1));
      expect(rows.single['originalId'], 'fgrt_test_a');
      expect(rows.single['verdict'], 'CONFIRMED');
    });

    test('rows are sorted newest-ratified-first', () {
      final older = contract(
        idSuffix: 'older',
        originalRunAt: DateTime.utc(2026, 4, 23),
        terminal: PendingRetestStatus.ratifiedConfirmed,
        ratifiedAt: DateTime.utc(2026, 4, 24, 9),
      );
      final newer = contract(
        idSuffix: 'newer',
        originalRunAt: DateTime.utc(2026, 4, 24),
        terminal: PendingRetestStatus.ratifiedOverturned,
        ratifiedAt: DateTime.utc(2026, 4, 25, 9),
      );
      final rows = PdfGeneratorService.debugBuildRatificationRows([
        older,
        newer,
      ]);
      expect(rows.map((r) => r['originalId']), [
        'fgrt_test_newer',
        'fgrt_test_older',
      ]);
      expect(rows.first['verdict'], 'OVERTURNED');
      expect(rows.last['verdict'], 'CONFIRMED');
    });

    test('row exposes original / ratified / ratifying timestamps', () {
      final originalAt = DateTime.utc(2026, 4, 24, 10);
      final ratifiedAt = DateTime.utc(2026, 4, 25, 11);
      final c = contract(
        idSuffix: 'x',
        originalRunAt: originalAt,
        terminal: PendingRetestStatus.ratifiedConfirmed,
        ratifiedAt: ratifiedAt,
      );
      final rows = PdfGeneratorService.debugBuildRatificationRows([c]);
      expect(rows.single['originalRunAt'], originalAt);
      expect(rows.single['ratifiedAt'], ratifiedAt);
      expect(rows.single['ratifyingRunAt'], ratifiedAt);
    });
  });

  group('debugBuildPendingRetestRows', () {
    PendingRetest pendingFor(DateTime originalAt) {
      return PendingRetest.forFailureRun(FourGatesRun(
        runAt: originalAt,
        gates: const [
          GateResult(gate: FourGate.capacity, open: true, evidence: ''),
          GateResult(gate: FourGate.visibility, open: true, evidence: ''),
          GateResult(gate: FourGate.optionality, open: true, evidence: ''),
          GateResult(gate: FourGate.election, open: true, evidence: ''),
        ],
      ));
    }

    test('only pending contracts appear; ratified are skipped', () {
      final pendingA = pendingFor(DateTime.utc(2026, 4, 25));
      final ratified = pendingFor(DateTime.utc(2026, 4, 24)).ratify(
        retestRun: FourGatesRun(
          runAt: DateTime.utc(2026, 4, 25, 13),
          gates: const [
            GateResult(gate: FourGate.capacity, open: true, evidence: ''),
            GateResult(gate: FourGate.visibility, open: true, evidence: ''),
            GateResult(gate: FourGate.optionality, open: true, evidence: ''),
            GateResult(gate: FourGate.election, open: true, evidence: ''),
          ],
        ),
        at: DateTime.utc(2026, 4, 25, 13),
      );
      final rows = PdfGeneratorService.debugBuildPendingRetestRows([
        pendingA,
        ratified,
      ]);
      expect(rows, hasLength(1));
      expect(rows.single['id'], pendingA.id);
      expect(rows.single['status'], 'PENDING');
    });

    test('rows are sorted newest-due-first', () {
      final older = pendingFor(DateTime.utc(2026, 4, 23));
      final newer = pendingFor(DateTime.utc(2026, 4, 25));
      final rows = PdfGeneratorService.debugBuildPendingRetestRows([
        older,
        newer,
      ]);
      expect(rows.map((r) => r['id']).toList(), [newer.id, older.id]);
    });

    test('row exposes originalRunAt and dueAt verbatim', () {
      final originalAt = DateTime.utc(2026, 4, 24, 10);
      final p = pendingFor(originalAt);
      final rows = PdfGeneratorService.debugBuildPendingRetestRows([p]);
      expect(rows.single['originalRunAt'], originalAt);
      expect(
        rows.single['dueAt'],
        originalAt.add(const Duration(hours: 24)),
      );
    });

    test('empty input produces empty output', () {
      expect(
        PdfGeneratorService.debugBuildPendingRetestRows(const []),
        isEmpty,
      );
    });
  });
}
