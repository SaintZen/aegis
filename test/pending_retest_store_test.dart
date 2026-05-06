import 'dart:convert';
import 'dart:math';

import 'package:anxiety_anchor/models/four_gates_run.dart';
import 'package:anxiety_anchor/models/pending_retest.dart';
import 'package:anxiety_anchor/services/pending_retest_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage tests for [PendingRetestStore]. Use the in-memory
/// `SharedPreferences` mock so we never hit the disk during tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PendingRetest makeRetest({
    required DateTime runAt,
    int seed = 0,
  }) =>
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

  group('PendingRetestStore.add / load', () {
    test('persists a single record and loads it back', () async {
      final store = PendingRetestStore();
      final r = makeRetest(runAt: DateTime.utc(2026, 4, 26, 12));
      await store.add(r);

      final loaded = await store.load();
      expect(loaded, hasLength(1));
      expect(loaded.single.id, r.id);
      expect(loaded.single.dueAt, r.dueAt);
    });

    test('stores multiple records sorted newest-due first', () async {
      final store = PendingRetestStore();
      final older = makeRetest(runAt: DateTime.utc(2026, 4, 24), seed: 1);
      final newer = makeRetest(runAt: DateTime.utc(2026, 4, 26), seed: 2);
      await store.add(older);
      await store.add(newer);

      final loaded = await store.load();
      expect(loaded.map((r) => r.id), [newer.id, older.id]);
    });

    test('replacing an existing id does not duplicate', () async {
      final store = PendingRetestStore();
      final r = makeRetest(runAt: DateTime.utc(2026, 4, 26), seed: 7);
      await store.add(r);
      await store.add(r); // same id
      final loaded = await store.load();
      expect(loaded, hasLength(1));
    });
  });

  group('PendingRetestStore.removeById', () {
    test('removes a known record and is a no-op for unknown ids', () async {
      final store = PendingRetestStore();
      final a = makeRetest(runAt: DateTime.utc(2026, 4, 26), seed: 1);
      final b = makeRetest(runAt: DateTime.utc(2026, 4, 25), seed: 2);
      await store.add(a);
      await store.add(b);

      await store.removeById(a.id);
      final loaded = await store.load();
      expect(loaded.map((r) => r.id), [b.id]);

      // No-op for unknown id.
      final beforeUnknownRemove = await store.load();
      await store.removeById('fgrt_does_not_exist');
      final afterUnknownRemove = await store.load();
      expect(
        afterUnknownRemove.map((r) => r.id),
        beforeUnknownRemove.map((r) => r.id),
      );
    });
  });

  group('PendingRetestStore.loadDue', () {
    test('returns only records whose dueAt has been reached', () async {
      final store = PendingRetestStore();
      final dueNow = makeRetest(
        runAt: DateTime.utc(2026, 4, 25, 12),
        seed: 1,
      ); // dueAt = 2026-04-26 12:00
      final notDueYet = makeRetest(
        runAt: DateTime.utc(2026, 4, 26, 12),
        seed: 2,
      ); // dueAt = 2026-04-27 12:00
      await store.add(dueNow);
      await store.add(notDueYet);

      final due = await store.loadDue(now: DateTime.utc(2026, 4, 26, 13));
      expect(due.map((r) => r.id), [dueNow.id]);
    });

    test('empty when nothing is due', () async {
      final store = PendingRetestStore();
      await store.add(makeRetest(runAt: DateTime.utc(2026, 4, 26, 12)));
      final due = await store.loadDue(now: DateTime.utc(2026, 4, 26, 13));
      expect(due, isEmpty);
    });
  });

  group('PendingRetestStore.clear', () {
    test('wipes all records', () async {
      final store = PendingRetestStore();
      await store.add(makeRetest(runAt: DateTime.utc(2026, 4, 26), seed: 1));
      await store.add(makeRetest(runAt: DateTime.utc(2026, 4, 25), seed: 2));
      await store.clear();
      expect(await store.load(), isEmpty);
    });
  });

  group('PendingRetestStore.update / loadDue / loadRatified (Phase 1.4-C)', () {
    test('update mutates the existing record in-place by id', () async {
      final store = PendingRetestStore();
      final pending = makeRetest(runAt: DateTime.utc(2026, 4, 25, 12));
      await store.add(pending);

      final ratified = pending.ratify(
        retestRun: FourGatesRun(
          runAt: DateTime.utc(2026, 4, 26, 13),
          gates: const [
            GateResult(gate: FourGate.capacity, open: true, evidence: ''),
            GateResult(gate: FourGate.visibility, open: true, evidence: ''),
            GateResult(gate: FourGate.optionality, open: true, evidence: ''),
            GateResult(gate: FourGate.election, open: true, evidence: ''),
          ],
        ),
        at: DateTime.utc(2026, 4, 26, 13, 5),
      );
      await store.update(ratified);

      final loaded = await store.load();
      expect(loaded, hasLength(1));
      expect(loaded.single.id, pending.id);
      expect(loaded.single.status, PendingRetestStatus.ratifiedConfirmed);
    });

    test(
        'loadDue excludes ratified records even when dueAt is in the past',
        () async {
      final store = PendingRetestStore();
      final pending = makeRetest(runAt: DateTime.utc(2026, 4, 25, 12));
      await store.add(pending);

      // Ratify it.
      final ratified = pending.ratify(
        retestRun: FourGatesRun(
          runAt: DateTime.utc(2026, 4, 26, 13),
          gates: const [
            GateResult(gate: FourGate.capacity, open: false, evidence: ''),
            GateResult(gate: FourGate.visibility, open: true, evidence: ''),
            GateResult(gate: FourGate.optionality, open: true, evidence: ''),
            GateResult(gate: FourGate.election, open: true, evidence: ''),
          ],
        ),
      );
      await store.update(ratified);

      final due = await store.loadDue(now: DateTime.utc(2026, 4, 27));
      expect(
        due,
        isEmpty,
        reason: 'A ratified contract is not due — it is resolved',
      );
    });

    test('loadRatified returns only ratified records, newest-first',
        () async {
      final store = PendingRetestStore();
      final older = makeRetest(runAt: DateTime.utc(2026, 4, 24), seed: 1);
      final newer = makeRetest(runAt: DateTime.utc(2026, 4, 25), seed: 2);
      final stillPending = makeRetest(
        runAt: DateTime.utc(2026, 4, 26),
        seed: 3,
      );
      await store.add(older);
      await store.add(newer);
      await store.add(stillPending);

      // Ratify both, with newer ratified later.
      await store.update(older.ratify(
        retestRun: FourGatesRun(
          runAt: DateTime.utc(2026, 4, 25, 9),
          gates: const [
            GateResult(gate: FourGate.capacity, open: true, evidence: ''),
            GateResult(gate: FourGate.visibility, open: true, evidence: ''),
            GateResult(gate: FourGate.optionality, open: true, evidence: ''),
            GateResult(gate: FourGate.election, open: true, evidence: ''),
          ],
        ),
        at: DateTime.utc(2026, 4, 25, 9, 30),
      ));
      await store.update(newer.ratify(
        retestRun: FourGatesRun(
          runAt: DateTime.utc(2026, 4, 26, 9),
          gates: const [
            GateResult(gate: FourGate.capacity, open: true, evidence: ''),
            GateResult(gate: FourGate.visibility, open: true, evidence: ''),
            GateResult(gate: FourGate.optionality, open: true, evidence: ''),
            GateResult(gate: FourGate.election, open: true, evidence: ''),
          ],
        ),
        at: DateTime.utc(2026, 4, 26, 9, 30),
      ));

      final ratifiedList = await store.loadRatified();
      expect(ratifiedList.map((r) => r.id), [newer.id, older.id]);
      // stillPending must NOT appear in loadRatified.
      expect(
        ratifiedList.any((r) => r.id == stillPending.id),
        isFalse,
      );
    });
  });

  group('PendingRetestStore corrupt-row tolerance', () {
    test('skips a corrupt row and keeps the valid ones', () async {
      // Seed one valid row + one garbage row directly via mock.
      final r = makeRetest(runAt: DateTime.utc(2026, 4, 26), seed: 1);
      SharedPreferences.setMockInitialValues({
        PendingRetestStore.storageKey: <String>[
          jsonEncode(r.toJson()),
          'this is not json',
        ],
      });

      final store = PendingRetestStore();
      final loaded = await store.load();
      expect(loaded.map((x) => x.id), [r.id]);
    });
  });
}
