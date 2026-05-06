import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:anxiety_anchor/screens/bridge_maintenance_ledger_screen.dart';
import 'package:anxiety_anchor/services/pdf_generator_service.dart';
import 'package:anxiety_anchor/services/pending_retest_store.dart';
import 'package:anxiety_anchor/services/telemetry.dart';
import 'package:anxiety_anchor/widgets/branded_anchor.dart';

/// Same accent as [BridgeMaintenanceLedgerScreen] / maintenance control.
const Color _kBridgeOrange = Color(0xFFFF8C00);

/// FAILURE-verdict accent. Reused on the FOUR GATES tile when at least
/// one re-test contract is due, so the operator's eye lands on the same
/// red used for the FAILURE STATUS banner — visual continuity with the
/// run that produced the contract.
const Color _kFailureRed = Color(0xFFFF4C4C);

/// Test seam: returns the count of pending re-tests whose `dueAt`
/// has been reached. Defaults to a real [PendingRetestStore] query.
typedef DueRetestCountFn = Future<int> Function({required DateTime now});

class BridgeScreen extends StatefulWidget {
  const BridgeScreen({super.key, this.dueRetestCount});

  /// Injection hook for tests. When `null` (production), a real
  /// [PendingRetestStore] is queried.
  final DueRetestCountFn? dueRetestCount;

  @override
  State<BridgeScreen> createState() => _BridgeScreenState();
}

class _BridgeScreenState extends State<BridgeScreen>
    with WidgetsBindingObserver {
  Timer? _anchorHapticTimer;
  Timer? _killSwitchTimer;
  bool _anchorPressed = false;
  int _hapticStep = 0;

  /// Latest known count of pending re-tests whose dueAt has passed.
  /// Refreshed on initState, on app resume, and after returning from
  /// the FOUR GATES route. Read-only — Phase 1.4-B has no resolution
  /// flow yet.
  int _dueRetestCount = 0;

  late final DueRetestCountFn _loadDueCount =
      widget.dueRetestCount ?? _defaultDueCount;

  static Future<int> _defaultDueCount({required DateTime now}) async {
    try {
      final list = await PendingRetestStore().loadDue(now: now);
      return list.length;
    } catch (_) {
      // Surface degradations cannot brick the Bridge — show zero on error.
      return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshRetestBadge();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshRetestBadge();
    }
  }

  Future<void> _refreshRetestBadge() async {
    int count;
    try {
      count = await _loadDueCount(now: DateTime.now());
    } catch (_) {
      // Defense in depth: even injected readers should not crash the
      // Bridge. The production reader already swallows its own errors;
      // this catch protects against third-party / test-time injectors.
      count = 0;
    }
    if (!mounted) return;
    if (count == _dueRetestCount) return;
    setState(() => _dueRetestCount = count);
  }

  @override
  Widget build(BuildContext context) {
    final anchorSize = MediaQuery.sizeOf(context).width * 0.4;
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Center(
                child: Text(
                  '4/8/24',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontFamily: 'RobotoMono',
                    fontSize: 12,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                IgnorePointer(
                                  child: Container(
                                    width: anchorSize * 2.35,
                                    height: anchorSize * 1.55,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: RadialGradient(
                                        center: const Alignment(0, -0.12),
                                        radius: 0.92,
                                        colors: const [
                                          Color(0xFF141414),
                                          Color(0xFF0A0A0A),
                                          Color(0xFF000000),
                                        ],
                                        stops: const [0.0, 0.45, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTapDown: (_) => _onAnchorPointerDown(),
                                  onTapUp: (_) => _onAnchorPointerRelease(),
                                  onTapCancel: _onAnchorPointerRelease,
                                  onLongPressStart: (_) =>
                                      _triggerKillSwitch(),
                                  child: Container(
                                    width: anchorSize,
                                    height: anchorSize,
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.white12),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          BrandedAnchor(
                                            size: anchorSize * 0.74,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            height: 1,
                                            width: anchorSize * 0.55,
                                            color: Colors.white
                                                .withValues(alpha: 0.11),
                                          ),
                                          const SizedBox(height: 8),
                                          const FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'CHECKPOINT SAVED',
                                              style: TextStyle(
                                                color: Color(0xFFFFA500),
                                                fontFamily: 'RobotoMono',
                                                letterSpacing: 2.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'Continue from here',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.6),
                                                fontFamily: 'RobotoMono',
                                                fontSize: 11,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: anchorSize,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await PdfGeneratorService.exportAuditLog();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ledger print stream launched.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.print, size: 16),
                            label: const Text(
                              'AUDIT',
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                letterSpacing: 1.0,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kBridgeOrange,
                              side: const BorderSide(
                                color: _kBridgeOrange,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: anchorSize,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const BridgeMaintenanceLedgerScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.tune, size: 16),
                            label: const Text(
                              'MAINTENANCE / LEDGER',
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                letterSpacing: 0.8,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kBridgeOrange,
                              side: const BorderSide(
                                color: _kBridgeOrange,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: anchorSize,
                          child: FocusTraversalGroup(
                            policy: OrderedTraversalPolicy(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildBridgeOutlet(
                                  label: 'NOT TODAY',
                                  semanticsHint:
                                      'Opens refusal scripts and emergency contacts',
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/not-today',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildBridgeOutlet(
                                  label: 'ASMR',
                                  semanticsHint: 'Opens sonic pharmacy',
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/pharmacy'),
                                ),
                                const SizedBox(height: 4),
                                _buildBridgeOutlet(
                                  label: 'DICTIONARY',
                                  semanticsHint: 'Opens AEGIS definitions',
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/resources',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildBridgeOutlet(
                                  label: 'ADVOCACY',
                                  semanticsHint: 'Opens shield tools',
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/advocacy',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildBridgeOutlet(
                                  label: 'FOUR GATES',
                                  semanticsHint: _dueRetestCount > 0
                                      ? 'Opens Four Gates. '
                                          '$_dueRetestCount re-test '
                                          '${_dueRetestCount == 1 ? 'is' : 'are'} '
                                          'due for ratification.'
                                      : 'Opens Four Gates. '
                                          'Counter-imagination '
                                          'interceptor that audits failure '
                                          'preconditions before the '
                                          'imagination rewrites the event.',
                                  leading: const _FourGatesGlyph(),
                                  subtitle:
                                      'Counter-imagination interceptor. Audits '
                                      'failure preconditions before the '
                                      'imagination rewrites the event.',
                                  retestBadgeCount: _dueRetestCount,
                                  onTap: () async {
                                    Telemetry.emit('four_gates_tile_open');
                                    await Navigator.pushNamed(
                                      context,
                                      '/four-gates',
                                    );
                                    // The operator may have created or
                                    // (in 1.4-C) ratified contracts during
                                    // the visit — refresh the badge.
                                    if (!mounted) return;
                                    await _refreshRetestBadge();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 4),
                          child: Text(
                            'AEGIS v1.0 — Operator Console',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.38),
                              fontFamily: 'RobotoMono',
                              fontSize: 10,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAnchorPointerDown() {
    _anchorPressed = true;
    _hapticStep = 0;
    _anchorHapticTimer?.cancel();
    _killSwitchTimer?.cancel();

    _runAnchorCompressionPulse(220);

    _killSwitchTimer = Timer(const Duration(milliseconds: 1250), () {
      if (_anchorPressed) {
        _triggerKillSwitch();
      }
    });
  }

  void _runAnchorCompressionPulse(int intervalMs) {
    if (!_anchorPressed) return;
    if (_hapticStep <= 2) {
      HapticFeedback.lightImpact();
    } else if (_hapticStep <= 5) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    _hapticStep += 1;
    final nextInterval = (intervalMs - 20).clamp(70, 220);
    _anchorHapticTimer?.cancel();
    _anchorHapticTimer = Timer(Duration(milliseconds: intervalMs), () {
      _runAnchorCompressionPulse(nextInterval);
    });
  }

  void _onAnchorPointerRelease() {
    _anchorPressed = false;
    _anchorHapticTimer?.cancel();
    _killSwitchTimer?.cancel();
  }

  void _triggerKillSwitch() {
    _onAnchorPointerRelease();
    Navigator.pushNamed(context, '/wormhole');
  }

  /// Outlet row: dark fill, orange border/text — matches maintenance / ledger accent.
  ///
  /// When [leading] is provided, it's rendered to the left of the centered
  /// label without altering the row's vertical padding so grid spacing is
  /// preserved across outlets.
  ///
  /// [retestBadgeCount] — when > 0, a small `[RETEST DUE]` (or
  /// `[RETEST DUE: N]`) badge is rendered between the label row and the
  /// subtitle in the FAILURE-red accent. Doctrine: a pending re-test is
  /// the durable footprint of a FAILURE verdict; visual continuity with
  /// the FAILURE STATUS banner reinforces that the contract is ongoing.
  Widget _buildBridgeOutlet({
    required String label,
    required VoidCallback onTap,
    String? semanticsHint,
    Widget? leading,
    String? subtitle,
    int retestBadgeCount = 0,
  }) {
    const labelStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontWeight: FontWeight.w500,
      letterSpacing: 1.2,
      fontSize: 12,
      color: _kBridgeOrange,
    );
    final Widget labelRow = leading == null
        ? Text(label, textAlign: TextAlign.center, style: labelStyle)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 10),
              Text(label, textAlign: TextAlign.center, style: labelStyle),
            ],
          );

    final Widget? badge = retestBadgeCount > 0
        ? Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: _kFailureRed, width: 1),
              ),
              child: Text(
                retestBadgeCount == 1
                    ? '[RETEST DUE]'
                    : '[RETEST DUE: $retestBadgeCount]',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'RobotoMono',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 9,
                  color: _kFailureRed,
                ),
              ),
            ),
          )
        : null;

    final List<Widget> bodyChildren = [
      labelRow,
      if (badge != null) badge,
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
            fontSize: 10,
            height: 1.3,
            color: _kBridgeOrange.withValues(alpha: 0.55),
          ),
        ),
      ],
    ];

    final Widget body = bodyChildren.length == 1
        ? bodyChildren.single
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: bodyChildren,
          );
    return Semantics(
      button: true,
      label: label,
      hint: semanticsHint ?? 'Opens $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: _kBridgeOrange.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          focusColor: _kBridgeOrange.withValues(alpha: 0.08),
          canRequestFocus: true,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D),
              border: Border.all(color: _kBridgeOrange, width: 1.5),
            ),
            child: body,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _anchorHapticTimer?.cancel();
    _killSwitchTimer?.cancel();
    super.dispose();
  }
}

/// FOUR GATES glyph: a 2×2 grid of four bordered squares, monochrome,
/// matched to the Bridge accent. Pure geometry — no gradients, no rounding.
class _FourGatesGlyph extends StatelessWidget {
  const _FourGatesGlyph();

  @override
  Widget build(BuildContext context) {
    Widget cell() => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            border: Border.all(color: _kBridgeOrange, width: 1),
          ),
        );
    return SizedBox(
      width: 14,
      height: 14,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [cell(), cell()],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [cell(), cell()],
          ),
        ],
      ),
    );
  }
}
