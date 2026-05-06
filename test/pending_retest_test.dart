import 'dart:convert';
import 'dart:math';

import 'package:anxiety_anchor/models/four_gates_run.dart';
import 'package:anxiety_anchor/models/pending_retest.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the [PendingRetest] data model.
///
/// These tests guard the doctrine-level invariants of the re-test
/// contract: only FAILURE runs can produce one, the due time is
/// exactly +24h, the gates are carried verbatim in canonical order,
/// and JSON round-trips are schema-stable.
void main() {
  FourGatesRun failureRun({DateTime? at}) => FourGatesRun(
        runAt: at ?? DateTime.utc(2026, 4, 26, 12),
        gates: const [
          GateResult(gate: FourGate.capacity, open: true, evidence: 'cap'),
          GateResult(gate: FourGate.visibility, open: true, evidence: 'vis'),
          GateResult(gate: FourGate.optionality, open: true, evidence: 'opt'),
          GateResult(gate: FourGate.election, open: true, evidence: 'ele'),
        ],
      );

  FourGatesRun overloadRun({DateTime? at}) => FourGatesRun(
        runAt: at ?? DateTime.utc(2026, 4, 26, 12),
        gates: const [
          GateResult(gate: FourGate.capacity, open: false, evidence: ''),
          GateResult(gate: FourGate.visibility, open: true, evidence: ''),
          GateResult(gate: FourGate.optionality, open: true, evidence: ''),
          GateResult(gate: FourGate.election, open: true, evidence: ''),
        ],
      );

  group('PendingRetest.forFailureRun', () {
    test('builds a contract from a FAILURE run with dueAt = runAt + 24h', () {
      final run = failureRun(at: DateTime.utc(2026, 4, 26, 12));
      final retest = PendingRetest.forFailureRun(
        run,
        random: Random(7),
      );
      expect(retest.originalRunAt, run.runAt);
      expect(retest.dueAt, run.runAt.add(const Duration(hours: 24)));
      expect(retest.status, PendingRetestStatus.pending);
      expect(retest.originalGates, hasLength(4));
      expect(retest.id, startsWith('fgrt_'));
    });

    test('throws if the run is OVERLOAD — only FAILURE produces a contract',
        () {
      final run = overloadRun();
      expect(
        () => PendingRetest.forFailureRun(run),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('preserves the four gates in canonical enum order', () {
      final run = failureRun();
      final retest = PendingRetest.forFailureRun(run, random: Random(1));
      for (var i = 0; i < FourGate.values.length; i++) {
        expect(retest.originalGates[i].gate, FourGate.values[i]);
        expect(retest.originalGates[i].open, true);
      }
    });

    test('id is unique across two runs at the same instant', () {
      // Same timestamp; different random suffix → different ids.
      final run = failureRun();
      final a = PendingRetest.forFailureRun(run, random: Random(1));
      final b = PendingRetest.forFailureRun(run, random: Random(2));
      expect(a.id, isNot(b.id));
    });
  });

  group('PendingRetest.isDue', () {
    final retest = PendingRetest.forFailureRun(
      failureRun(at: DateTime.utc(2026, 4, 26, 12)),
      random: Random(0),
    );

    test('false 1 second before dueAt', () {
      final now = retest.dueAt.subtract(const Duration(seconds: 1));
      expect(retest.isDue(now: now), isFalse);
    });

    test('true exactly at dueAt', () {
      expect(retest.isDue(now: retest.dueAt), isTrue);
    });

    test('true after dueAt', () {
      final now = retest.dueAt.add(const Duration(hours: 12));
      expect(retest.isDue(now: now), isTrue);
    });
  });

  group('PendingRetest JSON round-trip', () {
    test('toJson then fromJson reproduces all fields', () {
      final original = PendingRetest.forFailureRun(
        failureRun(at: DateTime.utc(2026, 4, 26, 12)),
        random: Random(42),
      );
      final encoded = jsonEncode(original.toJson());
      final decoded = PendingRetest.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(decoded.id, original.id);
      expect(decoded.originalRunAt, original.originalRunAt);
      expect(decoded.dueAt, original.dueAt);
      expect(decoded.status, original.status);
      for (var i = 0; i < FourGate.values.length; i++) {
        expect(decoded.originalGates[i].gate, original.originalGates[i].gate);
        expect(decoded.originalGates[i].open, original.originalGates[i].open);
        expect(
          decoded.originalGates[i].evidence,
          original.originalGates[i].evidence,
        );
      }
    });

    test('schemaVersion is stamped into every payload', () {
      final original = PendingRetest.forFailureRun(
        failureRun(),
        random: Random(0),
      );
      final json = original.toJson();
      expect(json['schemaVersion'], PendingRetest.schemaVersion);
    });

    test('fromJson defaults status to pending if absent (forward-compat)', () {
      final json = <String, dynamic>{
        'schemaVersion': 1,
        'id': 'fgrt_test_00000000',
        'originalRunAt': DateTime.utc(2026, 4, 26, 12).toIso8601String(),
        'dueAt': DateTime.utc(2026, 4, 27, 12).toIso8601String(),
        'originalGates': const [
          {'gate': 'capacity', 'open': true, 'evidence': ''},
          {'gate': 'visibility', 'open': true, 'evidence': ''},
          {'gate': 'optionality', 'open': true, 'evidence': ''},
          {'gate': 'election', 'open': true, 'evidence': ''},
        ],
        // status omitted on purpose
      };
      final decoded = PendingRetest.fromJson(json);
      expect(decoded.status, PendingRetestStatus.pending);
    });

    test('fromJson falls back to pending for unknown future status values',
        () {
      final json = <String, dynamic>{
        'schemaVersion': 99,
        'id': 'fgrt_test_00000000',
        'originalRunAt': DateTime.utc(2026, 4, 26, 12).toIso8601String(),
        'dueAt': DateTime.utc(2026, 4, 27, 12).toIso8601String(),
        'originalGates': const [
          {'gate': 'capacity', 'open': true, 'evidence': ''},
          {'gate': 'visibility', 'open': true, 'evidence': ''},
          {'gate': 'optionality', 'open': true, 'evidence': ''},
          {'gate': 'election', 'open': true, 'evidence': ''},
        ],
        'status': 'confirmed_some_future_state',
      };
      final decoded = PendingRetest.fromJson(json);
      expect(decoded.status, PendingRetestStatus.pending);
    });

    test('fromJson throws FormatException on unrecoverable rows', () {
      expect(
        () => PendingRetest.fromJson(<String, dynamic>{'totally': 'wrong'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PendingRetest.ratify (Phase 1.4-C)', () {
    final pending = PendingRetest.forFailureRun(
      failureRun(at: DateTime.utc(2026, 4, 25, 12)),
      random: Random(1),
    );

    test('FAILURE re-test → ratifiedConfirmed', () {
      final retestRun = failureRun(at: DateTime.utc(2026, 4, 26, 13));
      final result = pending.ratify(
        retestRun: retestRun,
        at: DateTime.utc(2026, 4, 26, 13, 5),
      );
      expect(result.status, PendingRetestStatus.ratifiedConfirmed);
      expect(result.ratifyingRunAt, retestRun.runAt);
      expect(result.ratifiedAt, DateTime.utc(2026, 4, 26, 13, 5));
      expect(result.id, pending.id, reason: 'id is preserved');
      expect(result.originalRunAt, pending.originalRunAt);
      expect(result.dueAt, pending.dueAt);
      expect(result.isRatified, isTrue);
    });

    test('OVERLOAD re-test → ratifiedOverturned', () {
      final retestRun = overloadRun(at: DateTime.utc(2026, 4, 26, 13));
      final result = pending.ratify(retestRun: retestRun);
      expect(result.status, PendingRetestStatus.ratifiedOverturned);
      expect(result.ratifyingRunAt, retestRun.runAt);
      expect(result.ratifiedAt, isNotNull);
    });

    test('throws StateError when ratifying an already-ratified contract',
        () {
      final once = pending.ratify(
        retestRun: failureRun(at: DateTime.utc(2026, 4, 26, 13)),
      );
      expect(
        () => once.ratify(
          retestRun: overloadRun(at: DateTime.utc(2026, 4, 27, 13)),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('JSON round-trip preserves ratification fields', () {
      final ratified = pending.ratify(
        retestRun: failureRun(at: DateTime.utc(2026, 4, 26, 13)),
        at: DateTime.utc(2026, 4, 26, 13, 5),
      );
      final encoded = jsonEncode(ratified.toJson());
      final decoded = PendingRetest.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(decoded.status, PendingRetestStatus.ratifiedConfirmed);
      expect(decoded.ratifiedAt, ratified.ratifiedAt);
      expect(decoded.ratifyingRunAt, ratified.ratifyingRunAt);
    });

    test(
        'fromJson with ratified status but missing timestamps degrades '
        'to pending', () {
      final json = <String, dynamic>{
        'schemaVersion': 2,
        'id': 'fgrt_test',
        'originalRunAt': DateTime.utc(2026, 4, 25).toIso8601String(),
        'dueAt': DateTime.utc(2026, 4, 26).toIso8601String(),
        'originalGates': const [
          {'gate': 'capacity', 'open': true, 'evidence': ''},
          {'gate': 'visibility', 'open': true, 'evidence': ''},
          {'gate': 'optionality', 'open': true, 'evidence': ''},
          {'gate': 'election', 'open': true, 'evidence': ''},
        ],
        'status': 'ratifiedConfirmed',
        // Timestamps deliberately omitted.
      };
      final decoded = PendingRetest.fromJson(json);
      expect(decoded.status, PendingRetestStatus.pending);
      expect(decoded.ratifiedAt, isNull);
      expect(decoded.ratifyingRunAt, isNull);
    });

    test('ratificationLedgerHeader uses CONFIRMED for FAILURE re-test', () {
      final header = PendingRetest.ratificationLedgerHeader(
        originalId: 'fgrt_abc_123',
        retestRun: failureRun(),
      );
      expect(header, '[RE-TEST OF fgrt_abc_123] CONFIRMED');
    });

    test('ratificationLedgerHeader uses OVERTURNED for OVERLOAD re-test', () {
      final header = PendingRetest.ratificationLedgerHeader(
        originalId: 'fgrt_abc_123',
        retestRun: overloadRun(),
      );
      expect(header, '[RE-TEST OF fgrt_abc_123] OVERTURNED');
    });
  });
}
