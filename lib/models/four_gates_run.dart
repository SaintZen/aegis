/// FOUR GATES — counter-imagination interceptor.
///
/// ## Doctrine (canonical — see .cursor/rules/four-gates-doctrine.mdc)
///
/// Four Gates is a temporal interceptor. It activates in the narrow
/// interval between an operator assigning the label "failure" to an
/// event and the imagination generating catastrophic projections. The
/// instrument tests whether failure was structurally possible by
/// evaluating four preconditions: capacity, visibility, optionality,
/// and election. If any precondition is absent, the event is
/// classified as overload, and overload does not authorize escalation
/// or self-destructive interpretation. The ledger output is the
/// durable record that the imagination cannot rewrite.
///
/// ## What this file is
///
/// This file is the **mechanism**: the [FourGate] enum (gate identity,
/// fixed order, fixed polarity), the [GateResult] record, the
/// [FourGatesStatus] verdict enum, and the [FourGatesRun] aggregate
/// that owns the verdict rule and the [FourGatesRun.formatLedger]
/// audit body.
///
/// The mechanism is not the product. The product is the **interception**
/// — the moment between Step 2 (self-label) and Step 3 (imagination
/// ignition) where this file's verdict gets read by the operator
/// before the imagination can rewrite the event. UI pacing,
/// placement, and copy in the surface files exist to protect that
/// window. Treat this file accordingly.
///
/// ## Invariants (do not violate without explicit operator approval)
///
/// * **Order locked.** Gates fire in enum order: capacity → visibility
///   → optionality → election. Reordering is a doctrine break.
/// * **Polarity locked.** OPEN = precondition present; CLOSED =
///   precondition absent. Inverting flips the verdict semantics.
/// * **Verdict locked.** ALL OPEN → FAILURE + `NEXT: re-test in 24h.`
///   ANY CLOSED → OVERLOAD + classification NOT FAILURE. The 24h
///   re-test exists because no FAILURE verdict may be ratified under
///   acute somatic load — do not remove it and do not generalize it
///   to the OVERLOAD path.
/// * **Verbatim audit body.** [FourGatesRun.formatLedger] is the
///   canonical record. `PdfGeneratorService` MUST emit it without
///   truncation. The 80-char Signal Input cap on the main audit
///   table does not apply here.
/// * **No therapy language.** This feature ships in Aegis voice:
///   mechanical, monospace-flavored, third-person ("the operator,"
///   "the instrument"). Comfort/coping/support words are forbidden.
///
/// ## Surface files
///
///  * `lib/screens/four_gates_screen.dart`        — interception UI
///  * `lib/services/four_gates_vault.dart`        — local persistence (last 5 runs)
///  * `lib/services/aegis_log_service.dart`       — Aegis log sink
///    (write via `logLedgerEntry(type: 'FOUR_GATES', content: …)`)
///  * `lib/services/pdf_generator_service.dart`   — Technical Audit
///    Log: dedicated FOUR GATES section, verbatim body
///  * `lib/data/dictionary_entries.dart`          — operator-facing
///    reference text for the instrument
///  * `.cursor/rules/four-gates-doctrine.mdc`     — binding doctrine
///    contract for any agent or contributor touching this surface
library anxiety_anchor.models.four_gates_run;

enum FourGate { capacity, visibility, optionality, election }

extension FourGateMeta on FourGate {
  /// Uppercase monospace label used in the Ledger row and gate titles.
  String get label {
    switch (this) {
      case FourGate.capacity:
        return 'CAPACITY';
      case FourGate.visibility:
        return 'VISIBILITY';
      case FourGate.optionality:
        return 'OPTIONALITY';
      case FourGate.election:
        return 'ELECTION';
    }
  }

  /// The binary question shown on the gate screen.
  String get question {
    switch (this) {
      case FourGate.capacity:
        return 'Was action available?';
      case FourGate.visibility:
        return 'Was the situation visible?';
      case FourGate.optionality:
        return 'Were viable options present?';
      case FourGate.election:
        return 'Was inaction a chosen state?';
    }
  }

  /// One-line operator-facing context that sits **above** the gate
  /// question on the Four Gates screen. Doctrine role: orientation
  /// before answer — the operator knows *what is being tested* before
  /// engaging the binary question. Without this, the gates read like
  /// a quiz; with it, they read like checkpoints. See cursor rule
  /// `four-gates-doctrine.mdc` §11 (Operator-facing scaffolding).
  ///
  /// First-person reflective by spec — gate questions ARE operator-
  /// direct by doctrine §6, and micro-headers are gate-question
  /// scaffolding. They MUST stay anchored to the locked semantics
  /// in §4 (Capacity / Visibility / Optionality / Election); do not
  /// drift into therapy or coaching voice.
  String get microHeader {
    switch (this) {
      case FourGate.capacity:
        return 'Did I have the means to act in that moment?';
      case FourGate.visibility:
        return 'Could I see what was actually happening?';
      case FourGate.optionality:
        return 'Were viable alternatives available?';
      case FourGate.election:
        return 'Was inaction my choice, or was it forced?';
    }
  }

  /// 1-based number used in the Ledger row ("GATE 1", "GATE 2", ...).
  ///
  /// Named `number` instead of `index` to avoid shadowing the built-in
  /// `Enum.index` getter (which is 0-based and cannot be overridden).
  int get number => index + 1;
}

/// Result for a single gate.
class GateResult {
  const GateResult({
    required this.gate,
    required this.open,
    required this.evidence,
  });

  final FourGate gate;

  /// `true` = OPEN, `false` = CLOSED.
  final bool open;

  /// Short free-text note the operator enters as evidence. Trimmed.
  final String evidence;

  Map<String, dynamic> toJson() => {
        'gate': gate.name,
        'open': open,
        'evidence': evidence,
      };

  factory GateResult.fromJson(Map<String, dynamic> json) {
    final name = json['gate'] as String;
    final gate = FourGate.values.firstWhere((g) => g.name == name);
    return GateResult(
      gate: gate,
      open: json['open'] as bool,
      evidence: (json['evidence'] as String?) ?? '',
    );
  }
}

enum FourGatesStatus { failure, overload }

extension FourGatesStatusLabel on FourGatesStatus {
  String get statusWord {
    switch (this) {
      case FourGatesStatus.failure:
        return 'FAILURE';
      case FourGatesStatus.overload:
        return 'OVERLOAD';
    }
  }

  /// "FAILURE" or "NOT FAILURE" — the second line of the Ledger footer.
  String get classificationWord {
    switch (this) {
      case FourGatesStatus.failure:
        return 'FAILURE';
      case FourGatesStatus.overload:
        return 'NOT FAILURE';
    }
  }
}

/// A single Four Gates run: fixed 4-gate list in enum order.
class FourGatesRun {
  FourGatesRun({
    required this.runAt,
    required this.gates,
  }) : assert(
          gates.length == FourGate.values.length,
          'FourGatesRun must carry exactly ${FourGate.values.length} gates '
          '(got ${gates.length})',
        ),
        assert(
          List<bool>.generate(
            FourGate.values.length,
            (i) => gates[i].gate == FourGate.values[i],
          ).every((ok) => ok),
          'FourGatesRun gates must be in canonical enum order.',
        );

  final DateTime runAt;
  final List<GateResult> gates;

  FourGatesStatus get status =>
      gates.every((g) => g.open) ? FourGatesStatus.failure : FourGatesStatus.overload;

  bool get isFailure => status == FourGatesStatus.failure;

  /// Next-step hint shown only for FAILURE runs, per spec.
  String? get nextStepLine =>
      status == FourGatesStatus.failure ? 'NEXT: re-test in 24h.' : null;

  /// Monospaced Ledger block. Column-aligned; intended for a `RobotoMono`
  /// text widget.
  String formatLedger() {
    final buf = StringBuffer()
      ..writeln('FOUR GATES')
      ..writeln('-----------');
    for (final g in gates) {
      buf.writeln(_formatGateRow(g));
    }
    buf
      ..writeln('-----------')
      ..writeln('${'STATUS:'.padRight(16)}${status.statusWord}')
      ..write('${'CLASSIFICATION:'.padRight(16)}${status.classificationWord}');
    final next = nextStepLine;
    if (next != null) {
      buf
        ..writeln()
        ..writeln('-----------')
        ..write(next);
    }
    return buf.toString();
  }

  static String _formatGateRow(GateResult g) {
    final bracket = g.open ? '[OPEN]' : '[CLOSED]';
    final evidence = g.evidence.trim();
    final evidenceCol = evidence.isEmpty ? '' : '"$evidence"';
    return 'GATE ${g.gate.number}  '
        '${g.gate.label.padRight(14)}'
        '${bracket.padRight(8)}'
        '   '
        '$evidenceCol';
  }

  Map<String, dynamic> toJson() => {
        'runAt': runAt.toUtc().toIso8601String(),
        'gates': gates.map((g) => g.toJson()).toList(),
      };

  factory FourGatesRun.fromJson(Map<String, dynamic> json) {
    final rawGates = (json['gates'] as List)
        .cast<Map<String, dynamic>>()
        .map(GateResult.fromJson)
        .toList();
    return FourGatesRun(
      runAt: DateTime.parse(json['runAt'] as String),
      gates: rawGates,
    );
  }
}
