import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import 'package:anxiety_anchor/services/calibration_service.dart';
import 'package:anxiety_anchor/widgets/hollow_orb.dart';

class AnxietyLabScreen extends StatefulWidget {
  const AnxietyLabScreen({super.key});

  @override
  State<AnxietyLabScreen> createState() => _AnxietyLabScreenState();
}

class _AnxietyLabScreenState extends State<AnxietyLabScreen>
    with SingleTickerProviderStateMixin {
  static const double _orbSizeBase = 150;
  double _orbSize = 150;
  static const double _orbGlow = 26;
  String _statusText = 'STATUS: STANDBY';
  Timer? _scanPulseTimer;
  Timer? _scanRampTimer;
  bool _scanHoldActive = false;
  bool _scanHasVibrator = false;
  bool _scanHasAmplitude = false;
  bool _scanCapabilitiesChecked = false;
  double _scanIntensity = 0.2;

  late final AnimationController _voidSpinController;
  late final AnimationController _orbPulseController;
  static const Duration _voidSpinDuration = Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    _voidSpinController = AnimationController(
      vsync: this,
      duration: _voidSpinDuration,
    );
    _orbPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    CalibrationService.getReducedMotion().then((v) {
      if (mounted) {
        setState(() => _reducedMotion = v);
        if (!v) _orbPulseController.repeat(reverse: true);
      }
    });
    _voidSpinController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        if (CalibrationService.hapticIntensitySync > 0) {
          CalibrationService.fireTacticalFeedback(fallback: HapticIntensity.light);
        }
        setState(() => _voidSpinFlare = true);
        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted) {
            setState(() {
              _voidSpinFlare = false;
              _voidSpinActive = false;
            });
            Navigator.pushNamed(context, '/wormhole').then((_) {
              if (mounted) setState(() => _statusText = 'STATUS: STANDBY');
            });
          }
        });
      }
    });
  }

  bool _voidSpinActive = false;
  bool _voidSpinFlare = false;
  bool _reducedMotion = false;

  void _startVoidSpin() {
    setState(() {
      _statusText = 'STATUS: DISPOSING...';
      _voidSpinActive = true;
    });
    _voidSpinController.forward(from: 0);
  }

  Future<void> _activateTool(String status, String route) async {
    setState(() => _statusText = status);
    if (route == '/vault') {
      await Navigator.pushNamed(
        context,
        '/vault-lock',
        arguments: '/vault',
      );
    } else {
      await Navigator.pushNamed(context, route);
    }
    if (!mounted) return;
    setState(() => _statusText = 'STATUS: STANDBY');
  }

  @override
  void dispose() {
    _scanPulseTimer?.cancel();
    _scanRampTimer?.cancel();
    _voidSpinController.dispose();
    _orbPulseController.dispose();
    Vibration.cancel();
    super.dispose();
  }

  Future<void> _ensureScanCapabilities() async {
    if (_scanCapabilitiesChecked) return;
    _scanHasVibrator = await Vibration.hasVibrator() ?? false;
    _scanHasAmplitude = await Vibration.hasAmplitudeControl() ?? false;
    _scanCapabilitiesChecked = true;
  }

  Future<void> _startScanHold() async {
    await _ensureScanCapabilities();
    _scanHoldActive = true;
    _scanIntensity = 0.2;
    _startScanPulseTimer();
    _startScanRamp();
  }

  void _startScanPulseTimer() {
    _scanPulseTimer?.cancel();
    _scanPulseTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _fireScanPulse(_scanIntensity);
    });
  }

  void _startScanRamp() {
    _scanRampTimer?.cancel();
    const rampDuration = Duration(seconds: 3);
    const stepMs = 500;
    final steps = rampDuration.inMilliseconds ~/ stepMs;
    final delta = (1.0 - 0.2) / steps;
    var step = 0;
    _scanRampTimer = Timer.periodic(const Duration(milliseconds: stepMs), (t) {
      if (!_scanHoldActive) {
        t.cancel();
        return;
      }
      step += 1;
      _scanIntensity = (_scanIntensity + delta).clamp(0.2, 1.0);
      if (step >= steps) {
        _scanIntensity = 1.0;
        t.cancel();
      }
    });
  }

  Future<void> _stopScanHold() async {
    if (!_scanHoldActive) return;
    _scanHoldActive = false;
    _scanRampTimer?.cancel();
    await _fadeOutScan();
  }

  Future<void> _fadeOutScan() async {
    final start = _scanIntensity;
    const steps = 4;
    for (var i = 1; i <= steps; i++) {
      final intensity = (start * (1 - i / steps)).clamp(0.0, 1.0);
      _fireScanPulse(intensity);
      await Future.delayed(const Duration(milliseconds: 150));
    }
    _scanPulseTimer?.cancel();
    if (_scanHasVibrator) {
      Vibration.cancel();
    }
  }

  void _fireScanPulse(double intensity) async {
    if (CalibrationService.hapticIntensitySync <= 0) return;
    final scale = await CalibrationService.getHapticIntensity();
    if (scale <= 0) return;
    final scaledIntensity = intensity * scale;
    if (!_scanHasVibrator) {
      CalibrationService.fireTacticalFeedback(fallback: HapticIntensity.light);
      return;
    }
    if (_scanHasAmplitude) {
      final amplitude = (scaledIntensity * 255).round().clamp(20, 255);
      Vibration.vibrate(duration: 40, amplitude: amplitude);
      return;
    }
    CalibrationService.fireTacticalFeedback(
      fallback: scaledIntensity < 0.5 ? HapticIntensity.light : HapticIntensity.medium,
    );
  }

  Color _resolveOrbGlow(Color defaultColor) {
    if (CalibrationService.sootheModeSync) {
      return const Color(0xFF94A3B8); // Silver
    }
    return defaultColor;
  }

  @override
  Widget build(BuildContext context) {
    final sootheMode = CalibrationService.sootheModeSync;
    final gradientColors = sootheMode
        ? [const Color(0xFF0A0A0A), Colors.black]
        : const [Color(0xFF001A33), Colors.black];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildGlassHeader('Grounding Lab'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  _statusText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: LayoutBuilder(
                builder: (context, constraints) {
                  return _buildLabLayout(constraints.biggest);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassHeader(String title) {
    // Audit / PDF export lives on the Bridge (canonical Technical Audit Log).
    // The Lab header intentionally has no export affordance to avoid
    // duplicate, partial PDFs.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolOrb({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color glow,
    required VoidCallback onTap,
    VoidCallback? onHoldStart,
    VoidCallback? onHoldEnd,
    VoidCallback? onHoldCancel,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: onHoldStart == null ? null : (_) => onHoldStart(),
      onLongPressEnd: onHoldEnd == null ? null : (_) => onHoldEnd(),
      onLongPressCancel: onHoldCancel,
      child: Column(
        children: [
          Container(
            width: _orbSize,
            height: _orbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.5),
              border: Border.all(color: glow.withOpacity(0.7), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: glow.withOpacity(0.35),
                  blurRadius: _orbGlow,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: glow.withOpacity(0.2),
                  blurRadius: _orbGlow * 1.8,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: _orbSize * 0.74,
                height: _orbSize * 0.74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                  color: Colors.black.withOpacity(0.3),
                ),
                child: Icon(icon, color: glow, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: _orbSize + 20,
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Symmetric arc: 45° spacing (no "Car Wreck"). Orbs at 45, 135, 225, 315.
  static const List<double> _orbAngles = [45, 135, 225, 315];

  Widget _buildLabLayout(Size size) {
    final arcAreaHeight = size.height;
    final centerX = size.width / 2;
    final arcCenterY = arcAreaHeight * 0.45;
    final arcRadius = math.min(size.width * 0.36, arcAreaHeight * 0.38);
    _orbSize = math.min(_orbSizeBase, arcRadius * 0.82);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: arcAreaHeight,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              if (_voidSpinActive)
                Positioned.fill(
                  child: _buildVoidSpinOverlay(
                    centerX: centerX,
                    centerY: arcCenterY,
                    arcRadius: arcRadius,
                  ),
                ),
              _buildOrbOnArc(
                centerX: centerX,
                centerY: arcCenterY,
                arcRadius: arcRadius,
                orbSize: _orbSize,
                angleDeg: _orbAngles[0],
                child: _buildToolOrb(
                  title: 'THE VAULT',
                  subtitle: 'Securing / Time',
                  description: 'Lock the weight away.',
                  icon: Icons.lock_outline_rounded,
                  glow: _resolveOrbGlow(Colors.blueAccent),
                  onTap: () => _activateTool(
                    'STATUS: SECURING...',
                    '/vault',
                  ),
                ),
              ),
              _buildOrbOnArc(
                centerX: centerX,
                centerY: arcCenterY,
                arcRadius: arcRadius,
                orbSize: _orbSize,
                angleDeg: _orbAngles[1],
                child: _buildVoidOrb(arcCenterY),
              ),
              _buildOrbOnArc(
                centerX: centerX,
                centerY: arcCenterY,
                arcRadius: arcRadius,
                orbSize: _orbSize,
                angleDeg: _orbAngles[2],
                child: _buildHollowNode(),
              ),
              _buildOrbOnArc(
                centerX: centerX,
                centerY: arcCenterY,
                arcRadius: arcRadius,
                orbSize: _orbSize,
                angleDeg: _orbAngles[3],
                child: _buildToolOrb(
                  title: 'THE FROST',
                  subtitle: 'Clearing / Touch',
                  description: 'Users have reported cold exposure helps reset the '
                      'Vagus Nerve.',
                  icon: Icons.ac_unit_rounded,
                  glow: _resolveOrbGlow(Colors.lightBlueAccent),
                  onTap: () => _activateTool(
                    'STATUS: SCRAPING...',
                    '/scraper',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrbOnArc({
    required double centerX,
    required double centerY,
    required double arcRadius,
    required double orbSize,
    required double angleDeg,
    required Widget child,
  }) {
    final rad = angleDeg * math.pi / 180;
    final x = centerX + arcRadius * math.cos(rad) - (orbSize / 2);
    final y = centerY - arcRadius * math.sin(rad) - (orbSize / 2);

    return Positioned(
      left: x,
      top: y,
      child: AnimatedBuilder(
        animation: _orbPulseController,
        builder: (context, _) {
          final pulse = _reducedMotion
              ? 1.0
              : 1.0 + (_orbPulseController.value * 0.03);
          return Transform.scale(
            scale: pulse,
            alignment: Alignment.center,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildVoidOrb(double center) {
    return _buildToolOrb(
      title: 'THE VOID',
      subtitle: 'Disposal / Spin',
      description: 'Users have reported discarding thoughts helps reduce '
          'cognitive load.',
      icon: Icons.blur_on,
      glow: _resolveOrbGlow(Colors.purpleAccent),
      onTap: _startVoidSpin,
    );
  }

  Widget _buildVoidSpinOverlay({
    required double centerX,
    required double centerY,
    required double arcRadius,
  }) {
    const voidAngleDeg = 135.0; // Void orb index 1
    final voidRad = voidAngleDeg * math.pi / 180;
    final voidCenterX = centerX + arcRadius * math.cos(voidRad);
    final voidCenterY = centerY - arcRadius * math.sin(voidRad);
    const startRadius = 100.0;
    const spiralTurns = 1.5;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _voidSpinController,
        builder: (context, _) {
          final t = _voidSpinController.value;
          final easedT = Curves.easeIn.transform(t);
          final r = startRadius * (1 - easedT);
          final theta = spiralTurns * math.pi * 2 * t;
          final x = voidCenterX + r * math.cos(theta) - 12;
          final y = voidCenterY + r * math.sin(theta) - 12;
          final scale = 1 - t;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: x,
                top: y,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_voidSpinFlare)
                Positioned(
                  left: voidCenterX - 20,
                  top: voidCenterY - 20,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent.withOpacity(0.8),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHollowNode() {
    return GestureDetector(
      onTap: () => _activateTool(
        'PHANTOM SIGNAL DETECTED // STABILIZING HOLLOW...',
        '/hollow',
      ),
      child: Column(
        children: [
          SizedBox(
            width: _orbSize,
            height: _orbSize,
            child: Center(
              child: HollowOrb(
                orbSize: _orbSize,
                orbGlow: _orbGlow,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'THE HOLLOW',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const Text(
            'Naming / Containing',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: _orbSize + 20,
            child: const Text(
              'The body remembers what the mind cannot see. '
              'Name the shape to contain the void.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
