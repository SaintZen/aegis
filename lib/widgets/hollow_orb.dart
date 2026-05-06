import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import 'package:anxiety_anchor/services/calibration_service.dart';
import 'package:anxiety_anchor/services/usage_log_service.dart';

/// THE HOLLOW — Right node in Grounding Lab.
/// Mirrors The Void: large orb with matte steel/obsidian gradient (Anchor aesthetic).
/// 60 BPM (1 Hz) haptic thrum + scaled Monolith breathing (2-2-2-2) on long-press.
class HollowOrb extends StatefulWidget {
  const HollowOrb({
    super.key,
    required this.orbSize,
    required this.orbGlow,
  });

  final double orbSize;
  final double orbGlow;

  @override
  State<HollowOrb> createState() => _HollowOrbState();
}

class _HollowOrbState extends State<HollowOrb>
    with TickerProviderStateMixin {
  bool _reducedMotion = false;

  /// Matte steel / obsidian — matches main Anchor aesthetic
  static const Color _matteSteelLight = Color(0xFF4A5568);
  static const Color _matteSteelMid = Color(0xFF2D3748);
  static const Color _matteSteelDark = Color(0xFF1A202C);
  static const Color _steelBorder = Color(0xFF718096);
  static const Color _steelIcon = Color(0xFFE2E8F0);

  bool _isActive = false;
  String _phase = 'IN';
  int _counter = 2;
  DateTime? _hollowStartTime;
  Timer? _hapticTimer;
  Timer? _breathTimer;
  CancelableOperation<void>? _hapticOp;
  late AnimationController _pulseController;

  /// Scaled Monolith: 2-2-2-2 (8 sec cycle)
  static const int _in = 2, _hold1 = 2, _out = 2, _hold2 = 2;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    CalibrationService.getReducedMotion().then((v) {
      if (mounted) setState(() => _reducedMotion = v);
    });
  }

  void _startHollow() {
    if (_isActive) return;
    _hollowStartTime = DateTime.now();
    setState(() {
      _isActive = true;
      _phase = 'IN';
      _counter = _in;
    });
    if (CalibrationService.hapticIntensitySync > 0) {
      CalibrationService.fireTacticalFeedback(fallback: HapticIntensity.heavy);
    }
    _start60BpmThrum();
    _startBreathCycle();
  }

  void _stopHollow() {
    if (!_isActive) return;
    final start = _hollowStartTime;
    _hollowStartTime = null;
    _isActive = false;
    _killHapticLoopInstantly();
    _breathTimer?.cancel();
    if (start != null) {
      final elapsed = DateTime.now().difference(start).inSeconds;
      if (elapsed > 0) {
        unawaited(UsageLogService.logAnchorUsage(
          flavor: 'The Hollow',
          durationSeconds: elapsed,
        ));
      }
    }
    setState(() {});
  }

  /// Kills the haptic loop instantly via CancelableOperation to prevent haptic ghosting.
  /// Also calls Vibration.cancel() to stop any lingering vibration.
  void _killHapticLoopInstantly() {
    _hapticOp?.cancel();
    _hapticOp = null;
    _hapticTimer?.cancel();
    _hapticTimer = null;
    Vibration.cancel();
  }

  /// Pulse entrainment thrum: BPM from calibration (50–70). Wrapped in CancelableOperation for instant kill on release.
  /// When haptic intensity is 0, does not start the thrum (saves battery, prevents overstimulation).
  void _start60BpmThrum() {
    _killHapticLoopInstantly();
    if (CalibrationService.hapticIntensitySync <= 0) return;
    CalibrationService.getPulseEntrainmentBpm().then((bpm) {
      final canceled = _hapticOp?.isCanceled ?? false;
      if (!_isActive || canceled) return;
      if (CalibrationService.hapticIntensitySync <= 0) return;
      final intervalMs = (60000 / bpm).round();
      final completer = Completer<void>();
      _hapticTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
        final canceled = _hapticOp?.isCanceled ?? true;
        if (canceled) return;
        if (CalibrationService.hapticIntensitySync <= 0) return;
        CalibrationService.fireTacticalFeedback(fallback: HapticIntensity.heavy);
      });
      _hapticOp = CancelableOperation.fromFuture(
        completer.future,
        onCancel: () {
          _hapticTimer?.cancel();
          _hapticTimer = null;
          Vibration.cancel();
          if (!completer.isCompleted) completer.complete();
        },
      );
    });
  }

  void _startBreathCycle() {
    _breathTimer?.cancel();
    _breathTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isActive) return;
      setState(() {
        if (_counter > 1) {
          _counter--;
        } else {
          _advancePhase();
        }
      });
    });
  }

  void _advancePhase() {
    if (_phase == 'IN') {
      _phase = 'HOLD';
      _counter = _hold1;
    } else if (_phase == 'HOLD') {
      _phase = 'OUT';
      _counter = _out;
    } else if (_phase == 'OUT') {
      _phase = 'REST';
      _counter = _hold2;
    } else {
      _phase = 'IN';
      _counter = _in;
    }
  }

  @override
  void dispose() {
    _killHapticLoopInstantly();
    _breathTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startHollow(),
      onLongPressEnd: (_) => _stopHollow(),
      onLongPressCancel: _stopHollow,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = _reducedMotion || !_isActive
              ? 1.0
              : 1.0 + (_pulseController.value * 0.08);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.orbSize,
              height: widget.orbSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    _matteSteelDark,
                    _matteSteelMid,
                    _matteSteelLight,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                border: Border.all(
                  color: _steelBorder.withOpacity(0.5),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _steelBorder.withOpacity(0.35),
                    blurRadius: widget.orbGlow,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: _steelBorder.withOpacity(0.2),
                    blurRadius: widget.orbGlow * 1.8,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: widget.orbSize * 0.74,
                  height: widget.orbSize * 0.74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1),
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: Center(
                    child: _isActive
                        ? Text(
                            '$_phase $_counter',
                            style: const TextStyle(
                              color: _steelIcon,
                              fontSize: 14,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Icon(
                            Icons.anchor,
                            color: _steelIcon,
                            size: 40,
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
