import 'dart:math';

import 'package:anxiety_anchor/models/four_gates_run.dart';

/// PENDING RETEST — the durable promise the audit log makes to the operator.
///
/// ## Doctrine (canonical — see .cursor/rules/four-gates-doctrine.mdc)
///
/// When a Four Gates run produces a `FAILURE` verdict, the ledger emits the
/// line `NEXT: re-test in 24h.` That line is not advisory text — it is a
/// contract. A `FAILURE` verdict is provisional until ratified or
/// overturned by a re-test 24 hours later, against fresh evidence. The
/// imagination spends the intervening day generating catastrophic
/// projections; the doctrine's claim is that those projections cannot
/// rewrite a verdict that is locked in time and required to be re-tested.
///
/// `PendingRetest` is the unit of that contract. One record per FAILURE
/// run. Created at `_finalize()` time, due at `runAt + 24h`, persisted
/// alongside (but separately from) the existing `FourGatesVault`.
///
/// ## What this file is
///
/// This is a **pure data model** — JSON in, JSON out, no I/O, no UI.
/// Phase 1.4-A wires it in at create-time only; status is always
/// [PendingRetestStatus.pending]. Phase 1.4-B surfaces it; Phase 1.4-C
/// extends the model to carry resolution data (additive — existing
/// stored records remain valid).
///
/// ## Invariants
///
/// * Only `FOUR GATES` runs whose verdict is `FAILURE` produce a record.
///   `OVERLOAD` is the resolved state; nothing to ratify.
/// * `dueAt == originalRunAt + 24h` exactly.
/// * `originalGates` carries the **canonical four gates in enum order** —
///   same invariant as `FourGatesRun.gates`.
/// * `id` is unique across the operator's lifetime. Phase 1.4-C will use
///   it to link a re-test ledger entry back to the original run.
/// * Persisted JSON includes `schemaVersion`. Newer code reading older
///   JSON must not crash; older code reading newer JSON must skip rows
///   it cannot parse rather than throwing.
class PendingRetest {
  PendingRetest({
    required this.id,
    required this.originalRunAt,
    required this.dueAt,
    required this.originalGates,
    this.status = PendingRetestStatus.pending,
    this.ratifiedAt,
    this.ratifyingRunAt,
  })  : assert(
          originalGates.length == FourGate.values.length,
          'PendingRetest must carry exactly ${FourGate.values.length} gates',
        ),
        assert(
          List<bool>.generate(
            FourGate.values.length,
            (i) => originalGates[i].gate == FourGate.values[i],
          ).every((ok) => ok),
          'PendingRetest gates must be in canonical enum order',
        ),
        assert(
          (status == PendingRetestStatus.pending) ==
              (ratifiedAt == null && ratifyingRunAt == null),
          'A pending contract has no ratification fields; a ratified '
          'contract has both ratifiedAt and ratifyingRunAt',
        );

  /// Schema version stamped into every persisted record.
  ///
  /// * v1 (Phase 1.4-A): pending-only contracts.
  /// * v2 (Phase 1.4-C): adds ratification fields and the
  ///   `ratifiedConfirmed` / `ratifiedOverturned` status values.
  ///   Older readers that fall back to `pending` for unknown statuses
  ///   will treat ratified records as still-open — that is a graceful
  ///   degradation, not a crash.
  static const int schemaVersion = 2;

  /// Stable unique identifier for this re-test contract. Format:
  /// `fgrt_<microsSinceEpoch>_<8hex>`. Phase 1.4-C will reference this
  /// from the re-test ledger entry to link verdicts.
  final String id;

  /// `runAt` of the original FAILURE run that produced this contract.
  final DateTime originalRunAt;

  /// Wall-clock moment the re-test window opens. Always
  /// `originalRunAt + 24h`.
  final DateTime dueAt;

  /// The four gates the operator opened in the original run, in canonical
  /// enum order. Phase 1.4-C will use the original evidence verbatim
  /// or as a baseline depending on the chosen re-test mode.
  final List<GateResult> originalGates;

  /// Lifecycle state of this contract. Either [PendingRetestStatus.pending]
  /// (created, awaiting re-test), [PendingRetestStatus.ratifiedConfirmed]
  /// (re-test produced FAILURE — the original verdict held), or
  /// [PendingRetestStatus.ratifiedOverturned] (re-test produced OVERLOAD
  /// — the original verdict was overturned by fresh evidence).
  final PendingRetestStatus status;

  /// Wall-clock moment the operator completed the re-test. Non-null iff
  /// `status` is one of the `ratified*` values.
  final DateTime? ratifiedAt;

  /// `runAt` of the FOUR GATES run that ratified this contract. Used by
  /// the audit log to link the ratifying run back to the original.
  final DateTime? ratifyingRunAt;

  /// `true` once `now` has reached or passed [dueAt]. Pure function —
  /// inject `now` so callers can test deterministically.
  bool isDue({required DateTime now}) => !now.isBefore(dueAt);

  /// Convenience: `true` if this contract has been ratified (either
  /// confirmed or overturned). The opposite of "still pending".
  bool get isRatified =>
      status == PendingRetestStatus.ratifiedConfirmed ||
      status == PendingRetestStatus.ratifiedOverturned;

  /// Returns a new [PendingRetest] reflecting the outcome of running the
  /// supplied [retestRun] against this contract.
  ///
  /// * If the re-test verdict is FAILURE → status becomes
  ///   `ratifiedConfirmed` (the original FAILURE held up).
  /// * If the re-test verdict is OVERLOAD → status becomes
  ///   `ratifiedOverturned` (fresh evidence overturned the verdict).
  ///
  /// Throws [StateError] if the contract has already been ratified —
  /// a contract is single-use and cannot be re-ratified.
  PendingRetest ratify({
    required FourGatesRun retestRun,
    DateTime? at,
  }) {
    if (isRatified) {
      throw StateError(
        'PendingRetest $id is already ratified (status=$status); '
        'a contract is single-use.',
      );
    }
    final newStatus = retestRun.isFailure
        ? PendingRetestStatus.ratifiedConfirmed
        : PendingRetestStatus.ratifiedOverturned;
    return PendingRetest(
      id: id,
      originalRunAt: originalRunAt,
      dueAt: dueAt,
      originalGates: originalGates,
      status: newStatus,
      ratifiedAt: (at ?? DateTime.now().toUtc()),
      ratifyingRunAt: retestRun.runAt,
    );
  }

  /// One-line audit-log header that prefixes the verbatim
  /// [FourGatesRun.formatLedger] body when the ratifying run is written
  /// to the audit log. Format:
  /// `[RE-TEST OF <originalId>] CONFIRMED|OVERTURNED`
  static String ratificationLedgerHeader({
    required String originalId,
    required FourGatesRun retestRun,
  }) {
    final verdict = retestRun.isFailure ? 'CONFIRMED' : 'OVERTURNED';
    return '[RE-TEST OF $originalId] $verdict';
  }

  /// Builds a fresh pending re-test from a FAILURE [FourGatesRun].
  /// Throws [ArgumentError] if the run's verdict is not `FAILURE` —
  /// only failures produce contracts.
  factory PendingRetest.forFailureRun(
    FourGatesRun run, {
    Random? random,
  }) {
    if (!run.isFailure) {
      throw ArgumentError(
        'PendingRetest.forFailureRun requires a FAILURE verdict; '
        'got ${run.status.statusWord}',
      );
    }
    final r = random ?? Random();
    final suffix = r.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
    final id = 'fgrt_${run.runAt.microsecondsSinceEpoch}_$suffix';
    return PendingRetest(
      id: id,
      originalRunAt: run.runAt,
      dueAt: run.runAt.add(const Duration(hours: 24)),
      originalGates: List<GateResult>.unmodifiable(run.gates),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'id': id,
        'originalRunAt': originalRunAt.toUtc().toIso8601String(),
        'dueAt': dueAt.toUtc().toIso8601String(),
        'originalGates':
            originalGates.map((g) => g.toJson()).toList(growable: false),
        'status': status.name,
        if (ratifiedAt != null)
          'ratifiedAt': ratifiedAt!.toUtc().toIso8601String(),
        if (ratifyingRunAt != null)
          'ratifyingRunAt': ratifyingRunAt!.toUtc().toIso8601String(),
      };

  /// Tolerant decoder. Throws [FormatException] for unrecoverable rows;
  /// callers are expected to skip-on-throw rather than crash.
  factory PendingRetest.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String;
      final originalRunAt = DateTime.parse(json['originalRunAt'] as String);
      final dueAt = DateTime.parse(json['dueAt'] as String);
      final rawGates = (json['originalGates'] as List).cast<dynamic>();
      final gates = rawGates
          .map((g) => GateResult.fromJson(g as Map<String, dynamic>))
          .toList(growable: false);
      final statusName = (json['status'] as String?) ?? 'pending';
      final status = PendingRetestStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => PendingRetestStatus.pending,
      );
      final ratifiedAtRaw = json['ratifiedAt'] as String?;
      final ratifyingRunAtRaw = json['ratifyingRunAt'] as String?;
      // Defensive: the constructor invariant requires both ratification
      // fields to be present iff the status is ratified*. If the JSON
      // is internally inconsistent (e.g. a ratified status with no
      // timestamps, or pending with timestamps), we degrade gracefully:
      // status wins. A pending-with-timestamps row drops the timestamps;
      // a ratified-without-timestamps row falls back to pending.
      final isRatifiedStatus = status == PendingRetestStatus.ratifiedConfirmed
          || status == PendingRetestStatus.ratifiedOverturned;
      if (!isRatifiedStatus) {
        return PendingRetest(
          id: id,
          originalRunAt: originalRunAt,
          dueAt: dueAt,
          originalGates: gates,
          status: status,
        );
      }
      if (ratifiedAtRaw == null || ratifyingRunAtRaw == null) {
        return PendingRetest(
          id: id,
          originalRunAt: originalRunAt,
          dueAt: dueAt,
          originalGates: gates,
          status: PendingRetestStatus.pending,
        );
      }
      return PendingRetest(
        id: id,
        originalRunAt: originalRunAt,
        dueAt: dueAt,
        originalGates: gates,
        status: status,
        ratifiedAt: DateTime.parse(ratifiedAtRaw),
        ratifyingRunAt: DateTime.parse(ratifyingRunAtRaw),
      );
    } catch (e) {
      throw FormatException('Invalid PendingRetest JSON: $e');
    }
  }
}

/// Lifecycle of a pending re-test contract.
///
/// * [pending] — created by `_finalize()`, awaiting a re-test.
/// * [ratifiedConfirmed] — re-test produced FAILURE: the original
///   FAILURE verdict held up against fresh evidence.
/// * [ratifiedOverturned] — re-test produced OVERLOAD: fresh evidence
///   overturned the original FAILURE classification.
///
/// Older code reading newer values must fall back to [pending] rather
/// than throwing — see the `firstWhere` orElse in
/// [PendingRetest.fromJson]. Doctrine: a pending contract is more
/// honest than a misread ratification.
enum PendingRetestStatus { pending, ratifiedConfirmed, ratifiedOverturned }
