import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:anxiety_anchor/models/four_gates_run.dart';
import 'package:anxiety_anchor/models/pending_retest.dart';
import 'package:anxiety_anchor/services/aegis_log_service.dart';
import 'package:anxiety_anchor/services/four_gates_vault.dart';
import 'package:anxiety_anchor/services/pending_retest_store.dart';
import 'package:anxiety_anchor/services/telemetry.dart';

/// Canonical Aegis-log `type` value for Four Gates runs.
/// Used by [PdfGeneratorService] to bucket runs into the dedicated
/// "FOUR GATES" section of the Technical Audit Log (verbatim body,
/// no 80-char truncation).
const String fourGatesLedgerType = 'FOUR_GATES';

/// Test seam: lets unit tests intercept the Aegis-log write performed by
/// [FourGatesScreen._finalize] without spinning up a real document directory.
typedef LogLedgerEntryFn = Future<void> Function({
  required String type,
  required String content,
});

/// Test seam: lets unit tests intercept the pending re-test write performed
/// by [FourGatesScreen._finalize] when a FAILURE verdict is produced.
/// Defaults to a real [PendingRetestStore] in production.
typedef RecordPendingRetestFn = Future<void> Function(PendingRetest retest);

/// Test seam: returns the list of pending re-tests whose `dueAt` has been
/// reached. Defaults to a real [PendingRetestStore.loadDue] in production.
typedef LoadDueRetestsFn = Future<List<PendingRetest>> Function({
  required DateTime now,
});

/// Test seam: replaces an existing [PendingRetest] in storage with a
/// ratified copy. Phase 1.4-C: invoked from `_finalize()` when the
/// operator completes a re-test against an open contract.
typedef UpdatePendingRetestFn = Future<void> Function(PendingRetest retest);

/// FOUR GATES — interception UI.
///
/// This screen is the **interception surface** for the Four Gates
/// instrument. Its job is to insert itself between Step 2 (the
/// operator's self-label "I failed") and Step 3 (the imagination's
/// catastrophic projection) and run the four-precondition audit
/// before the imagination can rewrite the event.
///
/// Walks the operator through CAPACITY, VISIBILITY, OPTIONALITY, and
/// ELECTION in fixed order, then renders the monospaced Ledger block
/// and the STATUS / CLASSIFICATION lines.
///
///  * Any CLOSED gate → STATUS: OVERLOAD, CLASSIFICATION: NOT FAILURE.
///  * All four OPEN → STATUS: FAILURE, CLASSIFICATION: FAILURE, with
///    the `NEXT: re-test in 24h.` directive appended (no FAILURE
///    verdict ratifies under acute somatic load).
///
/// **Pacing matters.** Any change that widens the latency between the
/// operator opening this screen and reaching GATE 1 — CAPACITY is a
/// regression against the interception window. No splash, no intro
/// animation, no consent gate.
///
/// Doctrine: see `lib/models/four_gates_run.dart` (file-level dartdoc)
/// and the binding rule at `.cursor/rules/four-gates-doctrine.mdc`.
class FourGatesScreen extends StatefulWidget {
  const FourGatesScreen({
    super.key,
    this.vault,
    this.logLedgerEntry,
    this.recordPendingRetest,
    this.loadDueRetests,
    this.updatePendingRetest,
  });

  /// Injection hook for tests. Defaults to a fresh [FourGatesVault].
  final FourGatesVault? vault;

  /// Injection hook for tests. Defaults to
  /// [AegisLogService.logLedgerEntry].
  final LogLedgerEntryFn? logLedgerEntry;

  /// Injection hook for tests. Defaults to a [PendingRetestStore]-backed
  /// writer that persists FAILURE re-test contracts to disk.
  /// Phase 1.4-A: only invoked for FAILURE verdicts; never for OVERLOAD.
  final RecordPendingRetestFn? recordPendingRetest;

  /// Injection hook for tests. Defaults to a [PendingRetestStore]-backed
  /// reader that returns contracts whose `dueAt` has been reached.
  /// Drives the read-only "RE-TEST DUE" banner (Phase 1.4-B).
  final LoadDueRetestsFn? loadDueRetests;

  /// Injection hook for tests. Defaults to a [PendingRetestStore]-backed
  /// writer that mutates an existing contract in place (used by the
  /// ratification flow in Phase 1.4-C).
  final UpdatePendingRetestFn? updatePendingRetest;

  @override
  State<FourGatesScreen> createState() => _FourGatesScreenState();
}

class _FourGatesScreenState extends State<FourGatesScreen> {
  static const _mono = TextStyle(
    fontFamily: 'RobotoMono',
    fontFamilyFallback: ['Courier', 'monospace'],
    color: Colors.white,
    height: 1.35,
    letterSpacing: 0.5,
  );

  late final FourGatesVault _vault = widget.vault ?? FourGatesVault();
  late final LogLedgerEntryFn _logLedgerEntry =
      widget.logLedgerEntry ?? AegisLogService.logLedgerEntry;
  late final RecordPendingRetestFn _recordPendingRetest =
      widget.recordPendingRetest ?? _defaultRecordPendingRetest;
  late final LoadDueRetestsFn _loadDueRetests =
      widget.loadDueRetests ?? _defaultLoadDueRetests;
  late final UpdatePendingRetestFn _updatePendingRetest =
      widget.updatePendingRetest ?? _defaultUpdatePendingRetest;

  static Future<void> _defaultRecordPendingRetest(PendingRetest retest) async {
    await PendingRetestStore().add(retest);
  }

  static Future<List<PendingRetest>> _defaultLoadDueRetests({
    required DateTime now,
  }) async {
    try {
      return await PendingRetestStore().loadDue(now: now);
    } catch (_) {
      // Surface degradations cannot brick the screen — show no banner.
      return const <PendingRetest>[];
    }
  }

  static Future<void> _defaultUpdatePendingRetest(PendingRetest retest) async {
    await PendingRetestStore().update(retest);
  }

  /// Currently-due pending re-tests, sorted newest-due-first.
  /// Refreshed on initState and after every ratification.
  List<PendingRetest> _dueRetests = const <PendingRetest>[];

  /// When non-null, the current run is a re-test of this contract
  /// (Phase 1.4-C). Set by [_startRetest] from the banner action,
  /// consumed by [_finalize] to write a ratification entry. Cleared
  /// by [_reset] when the operator starts a fresh run.
  PendingRetest? _activeRetest;

  /// Per-gate flag: did the operator tap `[REVEAL ORIGINAL]` for this
  /// gate? The original evidence is blind by default (Q1: C). Reveal
  /// is sticky for the duration of the re-test.
  final Map<FourGate, bool> _revealedOriginal = {
    for (final g in FourGate.values) g: false,
  };

  /// Set after a successful re-test ratification. Drives the result
  /// panel's `[RE-TEST OF fgrt_xxx] CONFIRMED|OVERTURNED` header.
  /// Null for fresh runs.
  String? _ratificationHeader;

  int _step = 0; // 0..3 = gates, 4 = result
  final Map<FourGate, bool?> _decisions = {
    for (final g in FourGate.values) g: null,
  };
  final Map<FourGate, TextEditingController> _evidence = {
    for (final g in FourGate.values) g: TextEditingController(),
  };
  FourGatesRun? _completedRun;
  List<FourGatesRun> _recent = const [];

  @override
  void initState() {
    super.initState();
    Telemetry.emit('four_gates_start');
    _refreshRecent();
    _refreshDueRetests();
  }

  Future<void> _refreshDueRetests() async {
    final list = await _loadDueRetests(now: DateTime.now());
    if (!mounted) return;
    setState(() => _dueRetests = list);
  }

  @override
  void dispose() {
    for (final c in _evidence.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _refreshRecent() async {
    final list = await _vault.load();
    if (!mounted) return;
    setState(() => _recent = list);
  }

  FourGate get _currentGate => FourGate.values[_step];

  void _decide(FourGate gate, bool open) {
    // Escalating haptic per gate index, per Aegis spec.
    switch (gate.number) {
      case 1:
        HapticFeedback.selectionClick();
        break;
      case 2:
        HapticFeedback.lightImpact();
        break;
      case 3:
        HapticFeedback.mediumImpact();
        break;
      case 4:
      default:
        HapticFeedback.heavyImpact();
    }
    setState(() => _decisions[gate] = open);
    Telemetry.emit('four_gates_gate_decided', {
      'gate': gate.name,
      'open': open,
    });
  }

  void _next() {
    if (_decisions[_currentGate] == null) return;
    if (_step < FourGate.values.length - 1) {
      setState(() => _step += 1);
      return;
    }
    _finalize();
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step -= 1);
  }

  Future<void> _finalize() async {
    final gates = FourGate.values
        .map((g) => GateResult(
              gate: g,
              open: _decisions[g]!,
              evidence: _evidence[g]!.text.trim(),
            ))
        .toList(growable: false);
    final run = FourGatesRun(runAt: DateTime.now().toUtc(), gates: gates);
    await _vault.append(run);

    // Re-test mode (Phase 1.4-C): if the operator opened this run via
    // the RE-TEST DUE banner, the resulting FourGatesRun is treated as
    // the ratifying run for the active contract. The audit log gets a
    // header line linking it back to the original by id; the contract
    // is mutated to ratifiedConfirmed / ratifiedOverturned; and if the
    // re-test itself produced FAILURE, a NEW contract is opened (24h
    // later) — the doctrine permits unbounded re-test chains because
    // the imagination's pressure does not subside on a fixed schedule.
    final retest = _activeRetest;
    final isRetest = retest != null;

    String? ratificationHeader;
    if (isRetest) {
      ratificationHeader = PendingRetest.ratificationLedgerHeader(
        originalId: retest.id,
        retestRun: run,
      );
    }

    // Feed the canonical Technical Audit Log. Body is the verbatim
    // monospaced ledger block; PdfGeneratorService renders it in the
    // FOUR GATES section without 80-char truncation. For re-tests we
    // prefix with the ratification header so the audit reader can
    // link the run back to its original contract by id.
    final ledgerBody = isRetest
        ? '$ratificationHeader\n${run.formatLedger()}'
        : run.formatLedger();
    try {
      await _logLedgerEntry(
        type: fourGatesLedgerType,
        content: ledgerBody,
      );
    } catch (_) {
      // Audit-log persistence is best-effort; UI flow must not stall on
      // a filesystem failure during a Snap.
    }

    if (isRetest) {
      // Mutate the active contract from `pending` to one of the two
      // ratified terminal states. Best-effort: if the mutation fails
      // (storage corrupt, disk full), the operator still sees the
      // verdict — the audit log already has the linkage. The banner
      // refresh will simply continue to show the contract as due,
      // which is the safer-than-silent failure mode.
      try {
        final ratified = retest.ratify(retestRun: run);
        await _updatePendingRetest(ratified);
        Telemetry.emit('four_gates_retest_ratified', {
          'verdict': run.isFailure ? 'CONFIRMED' : 'OVERTURNED',
          'original_id': retest.id,
        });
      } catch (_) {
        // Swallowed by design — see comment block above.
      }

      // Q6: A — chain. A re-test that itself produces FAILURE opens a
      // new contract for 24h hence. The original contract is closed
      // (ratifiedConfirmed); the new contract is independently
      // ratifiable. OVERLOAD on a re-test ends the chain.
      if (run.isFailure) {
        try {
          await _recordPendingRetest(PendingRetest.forFailureRun(run));
          Telemetry.emit('four_gates_pending_retest_recorded', {
            'chained_from': retest.id,
          });
        } catch (_) {
          // Same best-effort posture as the audit-log write above.
        }
      }
    } else {
      // Fresh run (not a re-test). FAILURE verdicts emit a re-test
      // contract — the verdict is provisional until ratified 24h later.
      // OVERLOAD is the resolved state and writes nothing.
      if (run.isFailure) {
        try {
          await _recordPendingRetest(PendingRetest.forFailureRun(run));
          Telemetry.emit('four_gates_pending_retest_recorded');
        } catch (_) {
          // Best-effort.
        }
      }
    }

    HapticFeedback.vibrate(); // The Snap.
    Telemetry.emit('four_gates_complete', {
      'status': run.status.name,
      'classification': run.status.classificationWord,
      'mode': isRetest ? 'retest' : 'fresh',
    });
    if (!mounted) return;
    setState(() {
      _completedRun = run;
      _ratificationHeader = ratificationHeader;
      _step = FourGate.values.length;
    });
    await _refreshRecent();
    // After ratification, the just-resolved contract is no longer due.
    // Refresh so the banner reflects reality on the next NEW RUN.
    await _refreshDueRetests();
  }

  Future<void> _copyLedger(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ledger row copied.', style: _mono),
        backgroundColor: Color(0xFF001220),
      ),
    );
    Telemetry.emit('four_gates_ledger_copied');
  }

  void _reset() {
    setState(() {
      _step = 0;
      _completedRun = null;
      _activeRetest = null;
      _ratificationHeader = null;
      for (final g in FourGate.values) {
        _decisions[g] = null;
        _evidence[g]!.clear();
        _revealedOriginal[g] = false;
      }
    });
  }

  /// Enters re-test mode for [contract]. Resets the gates, clears any
  /// prior fresh-run inputs, and sets `_activeRetest` so [_finalize]
  /// writes a ratification entry instead of an unrelated audit row.
  ///
  /// Doctrine: the re-test runs against **fresh** evidence. We do not
  /// pre-fill the evidence fields (Q1: C). The operator can peek at
  /// what they wrote 24h ago via the per-gate `[REVEAL ORIGINAL]`
  /// button, but they must enter the re-test answer themselves.
  void _startRetest(PendingRetest contract) {
    setState(() {
      _activeRetest = contract;
      _ratificationHeader = null;
      _completedRun = null;
      _step = 0;
      for (final g in FourGate.values) {
        _decisions[g] = null;
        _evidence[g]!.clear();
        _revealedOriginal[g] = false;
      }
    });
    Telemetry.emit('four_gates_retest_started', {
      'original_id': contract.id,
    });
  }

  /// Picks the longest-waiting due contract (oldest `originalRunAt`)
  /// and enters re-test mode against it. Banner action callback.
  void _runEarliestDueRetest() {
    if (_dueRetests.isEmpty) return;
    final earliest = _dueRetests.reduce(
      (a, b) => a.originalRunAt.isBefore(b.originalRunAt) ? a : b,
    );
    _startRetest(earliest);
  }

  void _toggleRevealOriginal(FourGate gate) {
    setState(() {
      _revealedOriginal[gate] = !(_revealedOriginal[gate] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isResult = _step == FourGate.values.length;
    final retest = _activeRetest;
    final isRetestMode = retest != null;
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _back,
        ),
        title: Text(
          isRetestMode ? 'RE-TEST' : 'FOUR GATES',
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            color: Colors.white,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The RE-TEST DUE banner is suppressed once a re-test is
              // in progress (would be redundant with the header below)
              // and on the result panel (the ratification header takes
              // its place).
              if (_dueRetests.isNotEmpty && !isRetestMode && !isResult) ...[
                _RetestDueBanner(
                  due: _dueRetests,
                  mono: _mono,
                  onRunRetest: _runEarliestDueRetest,
                ),
                const SizedBox(height: 12),
              ],
              if (isRetestMode && !isResult) ...[
                _RetestHeader(retest: retest, mono: _mono),
                const SizedBox(height: 12),
              ],
              // Doctrinal anchor: the micro-preamble appears ONLY on
              // Gate 1 (step == 0), in both fresh-run and re-test mode.
              // Repeating it on every gate would dilute orientation
              // into noise. See cursor rule §11 (Operator-facing
              // scaffolding).
              if (!isResult && _step == 0) ...[
                _MicroPreamble(mono: _mono),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: isResult && _completedRun != null
                    ? _ResultPanel(
                        run: _completedRun!,
                        onCopy: _copyLedger,
                        onReset: _reset,
                        onClose: () => Navigator.of(context).maybePop(),
                        recent: _recent,
                        mono: _mono,
                        ratificationHeader: _ratificationHeader,
                      )
                    : _GatePanel(
                        gate: _currentGate,
                        stepIndex: _step,
                        totalSteps: FourGate.values.length,
                        decision: _decisions[_currentGate],
                        evidence: _evidence[_currentGate]!,
                        onDecide: (open) => _decide(_currentGate, open),
                        onNext: _next,
                        mono: _mono,
                        originalGate: isRetestMode
                            ? retest.originalGates[_step]
                            : null,
                        revealedOriginal:
                            _revealedOriginal[_currentGate] ?? false,
                        onToggleReveal: isRetestMode
                            ? () => _toggleRevealOriginal(_currentGate)
                            : null,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GatePanel extends StatelessWidget {
  const _GatePanel({
    required this.gate,
    required this.stepIndex,
    required this.totalSteps,
    required this.decision,
    required this.evidence,
    required this.onDecide,
    required this.onNext,
    required this.mono,
    this.originalGate,
    this.revealedOriginal = false,
    this.onToggleReveal,
  });

  final FourGate gate;
  final int stepIndex;
  final int totalSteps;
  final bool? decision;
  final TextEditingController evidence;
  final ValueChanged<bool> onDecide;
  final VoidCallback onNext;
  final TextStyle mono;

  /// Re-test mode only: the original gate result the operator recorded
  /// 24h ago. Null on fresh runs. When non-null, the gate panel shows
  /// a `[REVEAL ORIGINAL]` toggle below the evidence field.
  final GateResult? originalGate;

  /// Re-test mode only: has the operator tapped `[REVEAL ORIGINAL]`
  /// for this gate? Sticky for the duration of this re-test run.
  final bool revealedOriginal;

  /// Re-test mode only: invoked when the operator taps the reveal
  /// toggle. Null in fresh-run mode (no toggle is rendered).
  final VoidCallback? onToggleReveal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIndicator(step: stepIndex, total: totalSteps, mono: mono),
        const SizedBox(height: 24),
        Text(
          'GATE ${gate.number} — ${gate.label}',
          style: mono.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        // Micro-header: one-line operator-facing context for what this
        // gate tests. Renders above the binary gate question. See
        // `FourGate.microHeader` and cursor rule §11.
        Text(
          gate.microHeader,
          key: ValueKey('gate_micro_header_${gate.name}'),
          style: mono.copyWith(
            fontSize: 13,
            color: Colors.white60,
            height: 1.35,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          gate.question,
          style: mono.copyWith(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _DecisionButton(
                label: 'OPEN',
                selected: decision == true,
                onTap: () => onDecide(true),
                mono: mono,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DecisionButton(
                label: 'CLOSED',
                selected: decision == false,
                onTap: () => onDecide(false),
                mono: mono,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'EVIDENCE',
          style: mono.copyWith(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: evidence,
          maxLength: 120,
          style: mono.copyWith(fontSize: 14),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            counterStyle: mono.copyWith(fontSize: 10, color: Colors.white38),
            hintText: 'short text input',
            hintStyle: mono.copyWith(color: Colors.white30),
            filled: true,
            fillColor: const Color(0xFF001220),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(color: Colors.white),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        if (originalGate != null) ...[
          const SizedBox(height: 12),
          _RevealOriginalBlock(
            original: originalGate!,
            revealed: revealedOriginal,
            onToggle: onToggleReveal ?? () {},
            mono: mono,
          ),
        ],
        const Spacer(),
        _PrimaryButton(
          label: stepIndex == totalSteps - 1
              ? (originalGate != null ? 'RUN RE-TEST' : 'RUN GATES')
              : 'NEXT GATE',
          enabled: decision != null,
          onTap: onNext,
          mono: mono,
        ),
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.run,
    required this.onCopy,
    required this.onReset,
    required this.onClose,
    required this.recent,
    required this.mono,
    this.ratificationHeader,
  });

  final FourGatesRun run;
  final ValueChanged<String> onCopy;
  final VoidCallback onReset;
  final VoidCallback onClose;
  final List<FourGatesRun> recent;
  final TextStyle mono;

  /// Re-test mode only: the `[RE-TEST OF fgrt_xxx] CONFIRMED|OVERTURNED`
  /// header the audit log received. Rendered above the LEDGER ENTRY
  /// block so the operator sees the linkage immediately. Null on fresh
  /// runs.
  final String? ratificationHeader;

  @override
  Widget build(BuildContext context) {
    final isRetest = ratificationHeader != null;
    final ledgerForCopy = isRetest
        ? '$ratificationHeader\n${run.formatLedger()}'
        : run.formatLedger();
    final ledger = run.formatLedger();
    final statusColor = run.isFailure ? const Color(0xFFFF4C4C) : Colors.white;
    return ListView(
      children: [
        if (isRetest) ...[
          Container(
            key: const ValueKey('four_gates_ratification_banner'),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: statusColor, width: 1.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RATIFICATION',
                  style: mono.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  ratificationHeader!,
                  style: mono.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          'LEDGER ENTRY',
          style: mono.copyWith(
            fontSize: 12,
            color: Colors.white54,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF001220),
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(2),
          ),
          child: SelectableText(
            ledger,
            style: mono.copyWith(fontSize: 13),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: statusColor, width: 1.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            'STATUS: ${run.status.statusWord}',
            key: const ValueKey('four_gates_status_banner'),
            style: mono.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _PrimaryButton(
                label: 'COPY LEDGER',
                enabled: true,
                onTap: () => onCopy(ledgerForCopy),
                mono: mono,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PrimaryButton(
                label: 'NEW RUN',
                enabled: true,
                onTap: onReset,
                mono: mono,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SecondaryButton(
          label: 'CLOSE',
          onTap: onClose,
          mono: mono,
        ),
        const SizedBox(height: 24),
        if (recent.isNotEmpty) ...[
          Text(
            'VAULT — LAST ${recent.length} RUN${recent.length == 1 ? '' : 'S'}',
            style: mono.copyWith(
              fontSize: 12,
              color: Colors.white54,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          for (final r in recent)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  r.formatLedger(),
                  style: mono.copyWith(fontSize: 11, color: Colors.white70),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Doctrinal anchor rendered above Gate 1 in both fresh-run and re-test
/// mode. Three-line third-person Aegis voice — the operator must know
/// **why** the Gates are firing before they answer. Without this, the
/// instrument reads like a quiz; with it, it reads like a checkpoint.
///
/// Copy is locked verbatim by cursor rule §11 (Operator-facing
/// scaffolding). Do not paraphrase. Do not move outside the Gate-1
/// step. If you need to add more orientation, add a §12; do not bloat
/// the preamble.
class _MicroPreamble extends StatelessWidget {
  const _MicroPreamble({required this.mono});

  final TextStyle mono;

  static const String _line1 =
      'Four Gates fires in the two-second window between self-label '
      'and imagination ignition.';
  static const String _line2 =
      'It tests whether failure was structurally possible.';
  static const String _line3 =
      'If the Gates close, the imagination cannot rewrite the event.';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Four Gates doctrinal preamble',
      child: Container(
        key: const ValueKey('four_gates_micro_preamble'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.white24, width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _line1,
              style: mono.copyWith(
                fontSize: 11,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _line2,
              style: mono.copyWith(
                fontSize: 11,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _line3,
              style: mono.copyWith(
                fontSize: 11,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.step,
    required this.total,
    required this.mono,
  });

  final int step;
  final int total;
  final TextStyle mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'GATE ${step + 1} / $total',
          style: mono.copyWith(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: List.generate(total, (i) {
              final filled = i <= step;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 2,
                  color: filled ? Colors.white : Colors.white24,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.mono,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle mono;

  @override
  Widget build(BuildContext context) {
    final border = selected ? Colors.white : Colors.white24;
    final fill = selected ? Colors.white : Colors.transparent;
    final text = selected ? Colors.black : Colors.white;
    return Listener(
      onPointerDown: (_) => onTap(),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: border, width: 1.4),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: mono.copyWith(
            color: text,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.mono,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final TextStyle mono;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Listener(
        onPointerDown: enabled ? (_) => onTap() : null,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            label,
            style: mono.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// RE-TEST DUE banner (Phase 1.4-B → 1.4-C).
///
/// Shown above the gates panel when at least one [PendingRetest] has
/// reached its `dueAt`. Phase 1.4-C adds [onRunRetest], which when
/// present renders a `RUN RE-TEST` action that drops the operator
/// into re-test mode against the longest-waiting due contract.
///
/// Doctrine: a FAILURE verdict is provisional until ratified. The
/// banner is the operator's standing reminder that the imagination
/// has been waiting 24h to re-litigate the verdict, and the audit
/// log is waiting for the operator to either CONFIRM or OVERTURN.
///
/// Visual: same FAILURE-red border as the FAILURE STATUS banner so
/// the operator's eye treats this as continuous with the original
/// verdict.
class _RetestDueBanner extends StatelessWidget {
  const _RetestDueBanner({
    required this.due,
    required this.mono,
    this.onRunRetest,
  });

  final List<PendingRetest> due;
  final TextStyle mono;

  /// Phase 1.4-C: invoked when the operator taps the `RUN RE-TEST`
  /// button. Null in pure read-only contexts (e.g. when the screen
  /// is already in re-test mode and the banner should not offer an
  /// action). When null, no button is rendered.
  final VoidCallback? onRunRetest;

  static const Color _failureRed = Color(0xFFFF4C4C);

  @override
  Widget build(BuildContext context) {
    final earliest = due
        .map((r) => r.originalRunAt)
        .reduce((a, b) => a.isBefore(b) ? a : b)
        .toLocal();
    final earliestStamp =
        '${earliest.year.toString().padLeft(4, '0')}-'
        '${earliest.month.toString().padLeft(2, '0')}-'
        '${earliest.day.toString().padLeft(2, '0')} '
        '${earliest.hour.toString().padLeft(2, '0')}:'
        '${earliest.minute.toString().padLeft(2, '0')}';

    final headerLabel = due.length == 1
        ? 'RE-TEST DUE'
        : 'RE-TEST DUE — ${due.length} PENDING';

    final subtext = due.length == 1
        ? 'FAILURE verdict from $earliestStamp '
            'is awaiting ratification.'
        : 'Earliest verdict: $earliestStamp. '
            '${due.length} contracts awaiting ratification.';

    return Semantics(
      liveRegion: true,
      label: '$headerLabel. $subtext',
      child: Container(
        key: const ValueKey('retest_due_banner'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: _failureRed, width: 1.2),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headerLabel,
              style: mono.copyWith(
                color: _failureRed,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtext,
              style: mono.copyWith(
                color: Colors.white70,
                fontSize: 11,
                height: 1.35,
              ),
            ),
            if (onRunRetest != null) ...[
              const SizedBox(height: 10),
              Listener(
                onPointerDown: (_) => onRunRetest!.call(),
                child: Container(
                  key: const ValueKey('retest_due_banner_run_button'),
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _failureRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'RUN RE-TEST',
                    style: mono.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Header shown above the gates while a re-test is in progress.
///
/// Anchors the operator to the verdict being re-litigated so they
/// know which event the four gates apply to. Mirrors the STATUS
/// banner's monospaced framing for visual continuity.
class _RetestHeader extends StatelessWidget {
  const _RetestHeader({required this.retest, required this.mono});

  final PendingRetest retest;
  final TextStyle mono;

  static const Color _failureRed = Color(0xFFFF4C4C);

  @override
  Widget build(BuildContext context) {
    final original = retest.originalRunAt.toLocal();
    final stamp = '${original.year.toString().padLeft(4, '0')}-'
        '${original.month.toString().padLeft(2, '0')}-'
        '${original.day.toString().padLeft(2, '0')} '
        '${original.hour.toString().padLeft(2, '0')}:'
        '${original.minute.toString().padLeft(2, '0')}';
    return Semantics(
      label: 'RE-TEST of FAILURE verdict from $stamp',
      child: Container(
        key: const ValueKey('retest_header'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: _failureRed, width: 1.2),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RE-TEST',
              style: mono.copyWith(
                color: _failureRed,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Verdict from $stamp',
              style: mono.copyWith(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            Text(
              'Re-run all four gates against fresh evidence.',
              style: mono.copyWith(
                color: Colors.white54,
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-gate `[REVEAL ORIGINAL]` block rendered below the evidence
/// field in re-test mode (Q1: C — blind by default).
///
/// The original gate decision and evidence are not pre-filled; the
/// operator must answer fresh. Tapping `REVEAL` shows the original
/// evidence verbatim so the operator can compare their two answers
/// without their own input being anchored on the prior one.
class _RevealOriginalBlock extends StatelessWidget {
  const _RevealOriginalBlock({
    required this.original,
    required this.revealed,
    required this.onToggle,
    required this.mono,
  });

  final GateResult original;
  final bool revealed;
  final VoidCallback onToggle;
  final TextStyle mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ORIGINAL EVIDENCE',
                  style: mono.copyWith(
                    color: Colors.white54,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    fontSize: 11,
                  ),
                ),
              ),
              Listener(
                onPointerDown: (_) => onToggle(),
                child: Container(
                  key: const ValueKey('reveal_original_button'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: Colors.white54),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    revealed ? 'HIDE' : 'REVEAL ORIGINAL',
                    style: mono.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (revealed) ...[
            const SizedBox(height: 8),
            Text(
              'GATE ${original.gate.number} — '
              '${original.open ? 'OPEN' : 'CLOSED'}',
              style: mono.copyWith(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              key: const ValueKey('original_evidence_text'),
              original.evidence.isEmpty ? '(no evidence recorded)' : '"${original.evidence}"',
              style: mono.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.mono,
  });

  final String label;
  final VoidCallback onTap;
  final TextStyle mono;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onTap(),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: mono.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
