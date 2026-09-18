import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:anxiety_anchor/services/aegis_log_service.dart';

/// SCRAM — the Priority-0 emergency stabilization ritual (formerly "Kill
/// Switch"). Reached by holding the SCRAM bar (Anchor page) or the 1.25s hold
/// on the Monolith Anchor (Bridge).
///
/// Doctrine (aegis-core §4): Lockout -> Navy Fade -> (wind-down) -> Snap ->
/// Return to Bridge. Unlike the Void or the Vault, SCRAM asks *nothing* of the
/// operator — no typing, no choices. It takes the wheel and walks the nervous
/// system down: a collapsing mass paired with a decelerating haptic pulse over
/// a short fixed window, ending in the Snap. It is locked down (system back is
/// disabled) but never a trap — a deliberate hold-to-exit is always present.
class ScramScreen extends StatefulWidget {
  const ScramScreen({super.key});

  @override
  State<ScramScreen> createState() => _ScramScreenState();
}

enum _ScramPhase { engaged, coolDown, snap }

class _ScramScreenState extends State<ScramScreen>
    with TickerProviderStateMixin {
  /// Length of the wind-down window. Short and fixed — no dials (this is not
  /// the Circuit Breaker); the operator only has to endure, not decide.
  static const Duration _windDown = Duration(seconds: 60);
  static const Color _obsidian = Color(0xFF000000);
  static const Color _navy = Color(0xFF001220);

  late final AnimationController _collapse; // drives mass shrink over _windDown
  late final AnimationController _pulse; // short per-beat glow pop

  Timer? _engagedTimer;
  Timer? _pulseTimer;
  Timer? _snapTimer;

  _ScramPhase _phase = _ScramPhase.engaged;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _collapse = AnimationController(vsync: this, duration: _windDown);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    // Entry: a single decisive "cut", then hold the lockout banner briefly.
    HapticFeedback.mediumImpact();
    _engagedTimer = Timer(const Duration(milliseconds: 1500), _beginCoolDown);
  }

  void _beginCoolDown() {
    if (!mounted) return;
    setState(() => _phase = _ScramPhase.coolDown);
    _collapse.forward();
    _collapse.addStatusListener(_onCollapseStatus);
    _scheduleNextPulse();
  }

  void _onCollapseStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _snap();
  }

  /// Decelerating pulse: interval lerps from ~0.9s (agitated) to ~3.0s (settled)
  /// as the mass collapses — the felt sense of a system winding down.
  void _scheduleNextPulse() {
    if (!mounted || _phase != _ScramPhase.coolDown) return;
    final t = _collapse.value;
    final intervalMs = (900 + (3000 - 900) * t).round();
    _pulseTimer = Timer(Duration(milliseconds: intervalMs), () {
      if (!mounted || _phase != _ScramPhase.coolDown) return;
      HapticFeedback.lightImpact();
      _pulse.forward(from: 0.0).then((_) {
        if (mounted) _pulse.reverse();
      });
      _scheduleNextPulse();
    });
  }

  Future<void> _snap() async {
    if (!mounted || _exiting) return;
    _pulseTimer?.cancel();
    setState(() => _phase = _ScramPhase.snap);
    // The Snap: final haptic discharge event.
    HapticFeedback.heavyImpact();
    unawaited(AegisLogService.logEntry(toolName: 'SCRAM', status: 'Stabilized'));
    _snapTimer = Timer(const Duration(milliseconds: 1900), _returnToBridge);
  }

  void _returnToBridge() {
    if (!mounted || _exiting) return;
    _exiting = true;
    // Return to the stable base (the tab shell / Bridge).
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _holdExit() async {
    if (_exiting) return;
    _exiting = true;
    _pulseTimer?.cancel();
    _engagedTimer?.cancel();
    _snapTimer?.cancel();
    if (_phase != _ScramPhase.snap) {
      unawaited(
        AegisLogService.logEntry(toolName: 'SCRAM', status: 'Aborted'),
      );
    }
    HapticFeedback.selectionClick();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _engagedTimer?.cancel();
    _pulseTimer?.cancel();
    _snapTimer?.cancel();
    _collapse.removeStatusListener(_onCollapseStatus);
    _collapse.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lockout: system back is disabled so the operator can't be yanked out
    // accidentally — the only way out is the deliberate hold-to-exit below.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _obsidian,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 900),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.4,
              colors: [
                _phase == _ScramPhase.engaged ? _obsidian : _navy,
                _obsidian,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildHeader(),
                  Expanded(child: Center(child: _buildCore())),
                  _buildFooter(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final String line;
    switch (_phase) {
      case _ScramPhase.engaged:
        line = 'SYSTEM OVERRIDE';
        break;
      case _ScramPhase.coolDown:
        line = 'SCRAM ENGAGED';
        break;
      case _ScramPhase.snap:
        line = 'INTEGRITY STABILIZED';
        break;
    }
    return Column(
      children: [
        Text(
          line,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontFamily: 'RobotoMono',
            fontSize: 14,
            letterSpacing: 3.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _phase == _ScramPhase.snap
              ? 'Reaction halted. Returning to the Bridge.'
              : 'The instrument has you. Nothing is required.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontFamily: 'RobotoMono',
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCore() {
    return AnimatedBuilder(
      animation: Listenable.merge([_collapse, _pulse]),
      builder: (context, _) {
        // Mass collapses from wide to a settled core as the window elapses.
        final collapse = Curves.easeInOut.transform(_collapse.value);
        final baseDiameter = 300.0 - (300.0 - 96.0) * collapse;
        final pop = 1.0 + 0.06 * _pulse.value;
        final diameter = baseDiameter * pop;
        final glow = _phase == _ScramPhase.snap
            ? 0.0
            : (0.28 + 0.22 * _pulse.value) * (1.0 - 0.5 * collapse);
        return SizedBox(
          width: 320,
          height: 320,
          child: Center(
            child: Container(
              width: diameter.clamp(48.0, 320.0),
              height: diameter.clamp(48.0, 320.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF0A0A0A),
                    Color(0xFF001A33),
                    Color(0xFF001220),
                  ],
                  stops: [0.35, 0.75, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFFF)
                        .withValues(alpha: glow.clamp(0.0, 0.6)),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.brightness_1,
                  size: 10 + 8 * math.max(0.0, 1.0 - collapse),
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    if (_phase == _ScramPhase.snap) {
      return const SizedBox(height: 44);
    }
    // Deliberate hold-to-exit — locked down, but never a trap.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _phase == _ScramPhase.coolDown ? 'SYSTEMS COOLING' : '',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontFamily: 'RobotoMono',
            fontSize: 10,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onLongPress: _holdExit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'HOLD TO EXIT',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontFamily: 'RobotoMono',
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
