import 'package:anxiety_anchor/models/four_gates_run.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GateResult open(FourGate g, [String e = '']) =>
      GateResult(gate: g, open: true, evidence: e);
  GateResult closed(FourGate g, [String e = '']) =>
      GateResult(gate: g, open: false, evidence: e);

  FourGatesRun buildRun(List<GateResult> gates) {
    return FourGatesRun(
      runAt: DateTime.utc(2026, 4, 18, 12, 0),
      gates: gates,
    );
  }

  group('FourGatesRun classification', () {
    test('all four OPEN → STATUS: FAILURE / CLASSIFICATION: FAILURE', () {
      final run = buildRun([
        open(FourGate.capacity),
        open(FourGate.visibility),
        open(FourGate.optionality),
        open(FourGate.election),
      ]);
      expect(run.status, FourGatesStatus.failure);
      expect(run.isFailure, isTrue);
      expect(run.status.statusWord, 'FAILURE');
      expect(run.status.classificationWord, 'FAILURE');
      expect(run.nextStepLine, 'NEXT: re-test in 24h.');
    });

    test('any single CLOSED gate → STATUS: OVERLOAD / NOT FAILURE', () {
      for (final closedGate in FourGate.values) {
        final gates = FourGate.values
            .map((g) => g == closedGate ? closed(g) : open(g))
            .toList();
        final run = buildRun(gates);
        expect(run.status, FourGatesStatus.overload,
            reason: 'closing ${closedGate.name} should yield OVERLOAD');
        expect(run.isFailure, isFalse);
        expect(run.status.statusWord, 'OVERLOAD');
        expect(run.status.classificationWord, 'NOT FAILURE');
        expect(run.nextStepLine, isNull);
      }
    });

    test('all four CLOSED → OVERLOAD', () {
      final run = buildRun([
        closed(FourGate.capacity),
        closed(FourGate.visibility),
        closed(FourGate.optionality),
        closed(FourGate.election),
      ]);
      expect(run.status, FourGatesStatus.overload);
      expect(run.status.classificationWord, 'NOT FAILURE');
    });
  });

  group('FourGatesRun.formatLedger', () {
    test('OVERLOAD run produces spec-aligned monospace block', () {
      final run = buildRun([
        open(FourGate.capacity, 'tools on hand'),
        closed(FourGate.visibility, 'signal arrived late'),
        open(FourGate.optionality, 'two viable paths'),
        closed(FourGate.election, 'not chosen'),
      ]);
      final ledger = run.formatLedger();
      expect(ledger, contains('FOUR GATES\n-----------'));
      expect(
        ledger,
        contains('GATE 1  CAPACITY      [OPEN]     "tools on hand"'),
      );
      expect(
        ledger,
        contains('GATE 2  VISIBILITY    [CLOSED]   "signal arrived late"'),
      );
      expect(
        ledger,
        contains('GATE 3  OPTIONALITY   [OPEN]     "two viable paths"'),
      );
      expect(
        ledger,
        contains('GATE 4  ELECTION      [CLOSED]   "not chosen"'),
      );
      expect(ledger, contains('STATUS:         OVERLOAD'));
      expect(ledger, contains('CLASSIFICATION: NOT FAILURE'));
      expect(ledger, isNot(contains('NEXT:')));
    });

    test('FAILURE run appends NEXT: re-test in 24h.', () {
      final run = buildRun([
        open(FourGate.capacity, 'a'),
        open(FourGate.visibility, 'b'),
        open(FourGate.optionality, 'c'),
        open(FourGate.election, 'd'),
      ]);
      final ledger = run.formatLedger();
      expect(ledger, contains('STATUS:         FAILURE'));
      expect(ledger, contains('CLASSIFICATION: FAILURE'));
      expect(ledger, endsWith('NEXT: re-test in 24h.'));
    });

    test('empty evidence renders no quoted column', () {
      final run = buildRun([
        open(FourGate.capacity),
        open(FourGate.visibility),
        open(FourGate.optionality),
        open(FourGate.election),
      ]);
      final ledger = run.formatLedger();
      for (final line in ledger.split('\n').where((l) => l.startsWith('GATE'))) {
        expect(line, isNot(contains('""')),
            reason: 'empty evidence should not render empty quotes in row: $line');
        expect(line.trimRight(), line.trimRight(),
            reason: 'trailing whitespace is acceptable, quotes are not');
      }
    });
  });

  group('FourGatesRun constructor guardrails', () {
    test('rejects wrong gate count', () {
      expect(
        () => FourGatesRun(
          runAt: DateTime.utc(2026, 4, 18),
          gates: [open(FourGate.capacity)],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects out-of-order gates', () {
      expect(
        () => FourGatesRun(
          runAt: DateTime.utc(2026, 4, 18),
          gates: [
            open(FourGate.visibility),
            open(FourGate.capacity),
            open(FourGate.optionality),
            open(FourGate.election),
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('FourGate.microHeader (operator-facing scaffolding)', () {
    // Locked verbatim by cursor rule §11.2. If you change one of these
    // strings, you are doing a doctrine revision — read §11.2, then
    // update the rule + this test together.
    const expected = <FourGate, String>{
      FourGate.capacity: 'Did I have the means to act in that moment?',
      FourGate.visibility: 'Could I see what was actually happening?',
      FourGate.optionality: 'Were viable alternatives available?',
      FourGate.election: 'Was inaction my choice, or was it forced?',
    };

    test('every gate exposes a non-empty micro-header', () {
      for (final g in FourGate.values) {
        expect(g.microHeader, isNotEmpty,
            reason: 'gate ${g.name} must carry a micro-header');
      }
    });

    test('micro-header copy is locked per §11.2', () {
      for (final g in FourGate.values) {
        expect(g.microHeader, expected[g],
            reason: 'gate ${g.name} micro-header drifted from the rule');
      }
    });

    test('micro-headers do not contain second-person voice', () {
      // §6: "No 'you,' no 'your,' no 'we,' no 'us,' in user-facing
      // Four Gates copy unless it appears in a gate question."
      // Micro-headers are scaffolding, not questions — guard against
      // future drift.
      final forbidden = RegExp(r'\b(you|your|yours|we|us|our)\b',
          caseSensitive: false);
      for (final g in FourGate.values) {
        expect(forbidden.hasMatch(g.microHeader), isFalse,
            reason: 'gate ${g.name} micro-header must not use second-'
                'person or first-person-plural voice');
      }
    });
  });

  group('FourGatesRun JSON roundtrip', () {
    test('toJson/fromJson preserves all fields', () {
      final original = buildRun([
        open(FourGate.capacity, 'one'),
        closed(FourGate.visibility, 'two'),
        open(FourGate.optionality, 'three'),
        closed(FourGate.election, 'four'),
      ]);
      final restored = FourGatesRun.fromJson(original.toJson());
      expect(restored.runAt.toIso8601String(),
          original.runAt.toIso8601String());
      expect(restored.gates.length, 4);
      for (var i = 0; i < 4; i++) {
        expect(restored.gates[i].gate, original.gates[i].gate);
        expect(restored.gates[i].open, original.gates[i].open);
        expect(restored.gates[i].evidence, original.gates[i].evidence);
      }
      expect(restored.status, original.status);
    });
  });
}
