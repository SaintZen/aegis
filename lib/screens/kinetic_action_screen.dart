import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:anxiety_anchor/models/audit_cue.dart';
import 'package:anxiety_anchor/models/somatic_sequence.dart';
import 'package:anxiety_anchor/services/aegis_log_service.dart';
import 'package:anxiety_anchor/services/haptics/somatic_controller.dart';
import 'package:anxiety_anchor/screens/system_clear_popup.dart';

class KineticActionScreen extends StatefulWidget {
  const KineticActionScreen({super.key, required this.exerciseType});

  final String exerciseType;

  @override
  State<KineticActionScreen> createState() => _KineticActionScreenState();
}

class _KineticActionScreenState extends State<KineticActionScreen>
    with TickerProviderStateMixin {
  Timer? _killTimer;
  bool _running = false;
  bool _showKillFlash = false;
  String? _auditText;
  late final AnimationController _glitchController;
  late final AnimationController _noiseController;
  SomaticController? _somaticController;
  Timer? _auditClearTimer;
  bool _stealthMode = false;
  bool _initReady = false;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _noiseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();
    _loadStealthMode();
  }

  Future<void> _loadStealthMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isStealth = prefs.getBool('stealth_mode') ?? false;
    _somaticController = SomaticController(
      playbackOffsets: const {
        'vision': -150,
        'feet': -150,
        'head': -150,
      },
      muteAudio: isStealth,
    );
    if (mounted) {
      setState(() {
        _stealthMode = isStealth;
        _initReady = true;
      });
      _startExercise();
    }
  }

  @override
  void dispose() {
    _killTimer?.cancel();
    _auditClearTimer?.cancel();
    _somaticController?.dispose();
    _glitchController.dispose();
    _noiseController.dispose();
    super.dispose();
  }

  void _startKillTimer() {
    _killTimer?.cancel();
    _killTimer = Timer(const Duration(seconds: 3), _emergencyStop);
  }

  void _cancelKillTimer() {
    _killTimer?.cancel();
    _killTimer = null;
  }

  Future<void> _emergencyStop() async {
    _killTimer?.cancel();
    await _somaticController?.emergencyStop();
    await AegisLogService.logEntry(
      toolName: _toolLabel(widget.exerciseType),
      status: 'Aborted',
    );
    if (!mounted) return;
    setState(() => _showKillFlash = true);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _startExercise() async {
    if (_running) return;
    _running = true;
    final controller = _somaticController;
    if (controller == null) return;
    controller.auditStream.listen(_handleAudit);
    await controller.play(_sequenceForExercise(widget.exerciseType));
    await _showSystemClearPopup();
    if (mounted) {
      setState(() => _running = false);
    }
  }

  SomaticSequence _sequenceForExercise(String exerciseType) {
    switch (exerciseType) {
      case 'wall_push':
        return const SomaticSequence(
          id: 'wall_push',
          audioAsset: 'assets/audio/kinetic_prompts/wall_push.mp3',
          hapticProfile: HapticProfile.heavy40Hz,
          auditCues: [
            AuditCue(
              label: 'VISION',
              at: Duration(seconds: 10),
              hold: Duration(milliseconds: 2500),
            ),
            AuditCue(
              label: 'FEET',
              at: Duration(seconds: 20),
              hold: Duration(milliseconds: 2500),
            ),
            AuditCue(
              label: 'HEAD',
              at: Duration(seconds: 25),
              hold: Duration(milliseconds: 2500),
            ),
          ],
        );
      case 'somatic_shaking':
        return const SomaticSequence(
          id: 'the_shake',
          audioAsset: 'assets/audio/kinetic_prompts/the_shake.mp3',
          hapticProfile: HapticProfile.staccato150ms,
          auditCues: [
            AuditCue(
              label: 'VISION',
              at: Duration(seconds: 8),
              hold: Duration(milliseconds: 1500),
            ),
            AuditCue(
              label: 'FEET',
              at: Duration(seconds: 15),
              hold: Duration(milliseconds: 1500),
            ),
            AuditCue(
              label: 'GROUNDED',
              at: Duration(seconds: 22),
              hold: Duration(milliseconds: 2000),
            ),
          ],
        );
      case 'muscle_clench':
        return const SomaticSequence(
          id: 'isometric',
          audioAsset: 'assets/audio/kinetic_prompts/isometric.mp3',
          hapticProfile: HapticProfile.linearRamp,
          auditCues: [
            AuditCue(
              label: 'BREATHE',
              at: Duration(seconds: 7),
              hold: Duration(milliseconds: 2000),
            ),
            AuditCue(
              label: 'VISION',
              at: Duration(seconds: 18),
              hold: Duration(milliseconds: 2000),
            ),
            AuditCue(
              label: 'STATUS: GREEN',
              at: Duration(seconds: 25),
              hold: Duration(milliseconds: 2000),
            ),
          ],
          rampSegments: [
            HapticRampSegment(
              start: Duration(seconds: 9),
              end: Duration(seconds: 16),
            ),
            HapticRampSegment(
              start: Duration(seconds: 20),
              end: Duration(seconds: 24),
            ),
          ],
        );
      case 'pulse':
        return const SomaticSequence(
          id: 'pulse',
          audioAsset: 'assets/audio/kinetic_prompts/the_pulse.mp3',
          hapticProfile: HapticProfile.syncThrum,
          auditCues: [
            AuditCue(
              label: 'FEEL FEET',
              at: Duration(seconds: 6),
              hold: Duration(milliseconds: 2000),
            ),
            AuditCue(
              label: 'VISION',
              at: Duration(seconds: 18),
              hold: Duration(milliseconds: 2000),
            ),
            AuditCue(
              label: 'LOCKED',
              at: Duration(seconds: 25),
              hold: Duration(milliseconds: 3000),
            ),
          ],
        );
      default:
        return const SomaticSequence(
          id: 'unknown',
          audioAsset: 'assets/audio/kinetic_prompts/wall_push.mp3',
          hapticProfile: HapticProfile.heavy40Hz,
        );
    }
  }

  Future<void> _handleAudit(AuditCue cue) async {
    if (!mounted) return;
    _auditClearTimer?.cancel();
    setState(() => _auditText = cue.label);
    await _glitchController.forward(from: 0);
    _auditClearTimer = Timer(cue.hold, () {
      if (mounted) {
        setState(() => _auditText = null);
      }
    });
  }

  Future<void> _showSystemClearPopup() async {
    if (!mounted) return;
    final controller = _somaticController;
    final result = await showDialog<SystemClearResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SystemClearPopup(),
    );

    final status = result == SystemClearResult.yes
        ? 'Success'
        : result == SystemClearResult.no
            ? 'Failure'
            : 'Incomplete';

    await AegisLogService.logEntry(
      toolName: _toolLabel(widget.exerciseType),
      status: status,
    );

    if (result == SystemClearResult.yes) {
      await controller?.playSystemVoice('log_success');
      await _setRecommendations(const <String>[]);
    } else if (result == SystemClearResult.no) {
      await controller?.playSystemVoice('log_failure');
      await _setRecommendations(const ['pulse']);
    } else {
      await _setRecommendations(const <String>[]);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _setRecommendations(List<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('armory_recommendations', keys);
  }

  String _toolLabel(String key) {
    switch (key) {
      case 'wall_push':
        return 'Wall Push';
      case 'somatic_shaking':
        return 'The Shake';
      case 'muscle_clench':
        return 'Isometric';
      case 'pulse':
        return 'The Pulse';
      default:
        return key;
    }
  }

  Widget _buildShield() {
    return AnimatedBuilder(
      animation: _noiseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.black,
                  ],
                  radius: 0.85,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.06),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(120),
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _NoisePainter(seed: _noiseController.value),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlitchText(String text) {
    return AnimatedBuilder(
      animation: _glitchController,
      builder: (context, child) {
        final jitter = (1.0 - _glitchController.value) * 6.0;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(jitter, 0),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 84,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  fontFamily: 'Roboto',
                  color: Colors.white,
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(-jitter, 2),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 84,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  fontFamily: 'Roboto',
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Kinetic Action'),
      ),
      body: RawGestureDetector(
        gestures: {
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(
              duration: const Duration(milliseconds: 800),
            ),
            (instance) {
              instance.onLongPress = _emergencyStop;
            },
          ),
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            if (!_initReady)
              const Center(
                child: CircularProgressIndicator(color: Colors.white54),
              )
            else
              Center(child: _buildShield()),
            if (_auditText != null && _initReady)
              Positioned.fill(
                child: Center(
                  child: _buildGlitchText(_auditText!),
                ),
              ),
            if (_showKillFlash)
              Positioned.fill(
                child: Container(color: Colors.red),
              ),
            if (_stealthMode)
              const Positioned(
                top: 16,
                right: 16,
                child: Icon(
                  Icons.vibration,
                  color: Colors.white54,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  _NoisePainter({required this.seed});

  final double seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.06);
    final random = Random(seed.hashCode);
    for (int i = 0; i < 220; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) =>
      oldDelegate.seed != seed;
}
