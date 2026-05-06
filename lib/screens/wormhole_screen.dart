import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'package:anxiety_anchor/services/kinetic_voice_engine.dart';

class WormholeScreen extends StatefulWidget {
  const WormholeScreen({super.key});

  @override
  State<WormholeScreen> createState() => _WormholeScreenState();
}

class _WormholeScreenState extends State<WormholeScreen>
    with TickerProviderStateMixin {
  late AnimationController vortexController;
  late AnimationController collapseController;
  late AnimationController _particleController;
  late Animation<double> _shatterAnimation;
  late Animation<double> _spinAnimation;
  late Animation<double> _purgeScale;
  late Animation<double> _glowAnimation;
  VideoPlayerController? _videoController;
  final AudioPlayer _player = AudioPlayer();

  final TextEditingController textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool released = false;
  bool _isActive = false;
  bool _isAbsorbing = false;
  bool _purgeComplete = false;
  bool _returnReady = false;
  List<Offset> particles = [];
  double _initialStress = 5.0;
  int _lastPurgeHapticMs = 0;
  bool _snapTriggered = false;
  Timer? _returnDelayTimer;

  @override
  void initState() {
    super.initState();

    vortexController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    _shatterAnimation = CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeInOutCubic,
    );
    _spinAnimation = Tween<double>(begin: 0.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _purgeScale = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: const Interval(0.22, 1.0, curve: Curves.easeInOutCubic),
      ),
    );
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: const Interval(0.66, 1.0, curve: Curves.easeOut),
      ),
    );

    _prepareBlackholeAudio();
    _initializeBlackholeVideo();
    _particleController.addListener(_handlePurgeHaptics);
    _particleController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_snapTriggered) {
        _snapTriggered = true;
        HapticFeedback.vibrate();
        // Snap moment: stop all active motion/audio immediately.
        _particleController.stop(canceled: false);
        vortexController.stop();
        _player.pause();
        if (mounted) {
          _setPurgeComplete();
        }
      }
    });
  }

  void _handlePurgeHaptics() {
    if (!_isAbsorbing || _snapTriggered) return;
    final progress = _particleController.value.clamp(0.0, 1.0);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final intervalMs = (360 - (progress * 240)).round(); // ~360ms -> ~120ms
    if (nowMs - _lastPurgeHapticMs < intervalMs) return;
    _lastPurgeHapticMs = nowMs;
    if (progress < 0.45) {
      HapticFeedback.lightImpact();
    } else if (progress < 0.8) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _initializeBlackholeVideo() async {
    try {
      final controller = VideoPlayerController.asset(
        'assets/videos/black_hole.mp4',
      );
      await controller.initialize();
      await controller.setPlaybackSpeed(0.5);
      await controller.play();
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      if (mounted) {
        setState(() => _videoController = controller);
      } else {
        _videoController = controller;
      }
    } catch (e) {
      debugPrint('Blackhole video missing: $e');
      await _videoController?.dispose();
      _videoController = null;
    }
  }

  Future<void> _prepareBlackholeAudio() async {
    try {
      await _player.setLoopMode(LoopMode.one);
      await _player.setAsset('assets/audio/Blackhole/blackhole.aac');
      await _player.load();
    } catch (e) {
      debugPrint('Blackhole audio missing: $e');
    }
  }

  @override
  void dispose() {
    vortexController.dispose();
    collapseController.dispose();
    _particleController.dispose();
    textController.dispose();
    _inputFocusNode.dispose();
    _player.dispose();
    _videoController?.dispose();
    _returnDelayTimer?.cancel();
    super.dispose();
  }

  void _setPurgeComplete() {
    _returnDelayTimer?.cancel();
    setState(() {
      _isAbsorbing = false;
      _purgeComplete = true;
      _returnReady = false;
    });
    _returnDelayTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted || !_purgeComplete) return;
      setState(() => _returnReady = true);
    });
  }

  void _toggleBlackhole() {
    setState(() => _isActive = !_isActive);
    if (_isActive) {
      vortexController.repeat();
      _player.play();
    } else {
      vortexController.stop();
      _player.pause();
    }
  }

  Future<void> _shredThought() async {
    if (textController.text.trim().isEmpty || _isAbsorbing) return;
    FocusScope.of(context).unfocus();
    _createShatterParticles();
    setState(() {
      _isAbsorbing = true;
      _purgeComplete = false;
    });
    _snapTriggered = false;
    _lastPurgeHapticMs = 0;
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted || !_isAbsorbing) return;
    _rampVolume(from: 0.7, to: 1.2, steps: 8, stepMs: 85);
    await _particleController.forward(from: 0.0);
    if (!mounted) return;
    textController.clear();
    if (!_snapTriggered) {
      HapticFeedback.vibrate();
      _particleController.stop(canceled: false);
      vortexController.stop();
      _player.pause();
      _setPurgeComplete();
    }
  }

  void _releaseToVoid() {
    _shredThought();
  }

  void _createShatterParticles() {
    final random = Random();
    setState(() {
      particles = List.generate(
        30,
        (index) {
          final theta = random.nextDouble() * 2 * pi;
          final radius = 60 + random.nextDouble() * 110;
          return Offset(cos(theta) * radius, sin(theta) * radius);
        },
      );
    });
  }

  Future<void> _rampVolume({
    required double from,
    required double to,
    required int steps,
    required int stepMs,
  }) async {
    final delta = (to - from) / steps;
    var current = from;
    for (var i = 0; i <= steps; i++) {
      if (!mounted || !_isAbsorbing) return;
      await _player.setVolume(current.clamp(0.0, 1.2));
      current += delta;
      await Future.delayed(Duration(milliseconds: stepMs));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff050510),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
            final isKeyboardOpen = keyboardInset > 0;
            final circleSize = isKeyboardOpen ? 196.0 : 280.0;
            return Stack(
              children: [
                Positioned(
                  top: 24,
                  left: 0,
                  right: 0,
                  child: const Text(
                    'THE BLACKHOLE MASS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 24,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                Positioned(
                  right: -50,
                  top: constraints.maxHeight * 0.2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: circleSize,
                    height: circleSize,
                    child: _buildBlackholeOrb(),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 100,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    transform: Matrix4.identity()
                      ..scale(isKeyboardOpen ? 0.7 : 1.0),
                    transformAlignment: Alignment.bottomLeft,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: SizedBox(
                        width: 300,
                        child: Slider(
                          value: _initialStress,
                          min: 1,
                          max: 10,
                          activeColor: const Color(0xFF738678),
                          onChanged: (val) =>
                              setState(() => _initialStress = val),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 30,
                  bottom: 410,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    transform: Matrix4.identity()
                      ..scale(isKeyboardOpen ? 0.7 : 1.0),
                    transformAlignment: Alignment.bottomLeft,
                    child: Text(
                      'STATUS: ${_initialStress.toInt()}/10',
                      style: const TextStyle(
                        letterSpacing: 2,
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
                if (!_isAbsorbing && !_purgeComplete)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: keyboardInset + 90,
                    child: _buildVoidInputPanel(),
                  ),
                if (!_isAbsorbing && !_purgeComplete)
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: keyboardInset + 20,
                    child: _buildVoidActionButton(),
                  ),
                if (_isAbsorbing || _purgeComplete)
                  Positioned.fill(
                    child: _buildPurgeOverlay(
                      constraints: constraints,
                      keyboardInset: keyboardInset,
                      circleSize: circleSize,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBlackholeOrb() {
    return GestureDetector(
      onTap: _toggleBlackhole,
      child: AnimatedBuilder(
        animation: vortexController,
        builder: (context, child) {
          final baseGlow = (_isActive || _isAbsorbing) ? 1.0 : 0.4;
          final glow =
              baseGlow + (_isAbsorbing ? _glowAnimation.value * 0.6 : 0.0);
          return AnimatedScale(
            scale: _isAbsorbing ? 0.85 : 1.0,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            child: SizedBox(
              height: 280,
              width: 280,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(150),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_videoController != null &&
                        _videoController!.value.isInitialized)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.black,
                              Colors.deepPurple[900]!,
                            ],
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _shatterAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: ShatterPainter(
                              progress: _shatterAnimation.value,
                              offsets: particles,
                            ),
                          );
                        },
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.5 * glow),
                            blurRadius: 30 * glow,
                            spreadRadius: 10 * glow,
                          ),
                        ],
                      ),
                      child: Center(
                        child: GestureDetector(
                          onLongPressStart: (_) =>
                              KineticVoiceEngine.startEngineThrum(),
                          onLongPressEnd: (_) =>
                              KineticVoiceEngine.stopEngineThrum(),
                          onLongPressCancel: () =>
                              KineticVoiceEngine.stopEngineThrum(),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.blur_on,
                                size: 80,
                                color: Colors.white70,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Dizzy? Just let go.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
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
          );
        },
      ),
    );
  }

  Widget _buildVoidInputPanel() {
    return Column(
      children: [
        ScaleTransition(
          alignment: Alignment.topCenter,
          scale: Tween<double>(begin: 1.0, end: 0.0).animate(_shatterAnimation),
          child: FadeTransition(
            opacity:
                Tween<double>(begin: 1.0, end: 0.0).animate(_shatterAnimation),
            child: RotationTransition(
              turns: _spinAnimation,
              child: _buildVoidScriptBox(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoidActionButton() {
    return ElevatedButton(
      onPressed: _releaseToVoid,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
      ),
      child: const Text(
        'Release To The Void',
        style: TextStyle(
          fontSize: 16,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Alignments in Stack coordinates: bubble (bottom intake) → black hole (top-right mass).
  Alignment _voidBubbleStartAlign(double w, double h, double keyboardInset) {
    final py = h - keyboardInset - 195;
    final ay = ((py - h / 2) / (h / 2)).clamp(-1.0, 1.0);
    return Alignment(0, ay);
  }

  Alignment _blackholeTargetAlign(double w, double h, double circleSize) {
    final cx = w + 50 - circleSize / 2;
    final cy = h * 0.2 + circleSize / 2;
    final ax = ((cx - w / 2) / (w / 2)).clamp(-1.0, 1.0);
    final ay = ((cy - h / 2) / (h / 2)).clamp(-1.0, 1.0);
    return Alignment(ax, ay);
  }

  Widget _buildPurgeOverlay({
    required BoxConstraints constraints,
    required double keyboardInset,
    required double circleSize,
  }) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    return Container(
      color: Colors.black.withValues(alpha: 0.22),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              final raw = _particleController.value.clamp(0.0, 1.0);
              final travelT = Curves.easeInOutCubic.transform(raw);
              final begin = _voidBubbleStartAlign(w, h, keyboardInset);
              final end = _blackholeTargetAlign(w, h, circleSize);
              final base = Alignment.lerp(begin, end, travelT)!;
              final orbitalRadius = (1.0 - travelT) * 0.14;
              final theta = _spinAnimation.value * 2 * pi;
              final spiralDx = cos(theta) * orbitalRadius;
              final spiralDy = sin(theta) * orbitalRadius;

              return Align(
                alignment: Alignment(
                  (base.x + spiralDx).clamp(-1.0, 1.0),
                  (base.y + spiralDy).clamp(-1.0, 1.0),
                ),
                child: Transform.scale(
                  scale: _purgeScale.value,
                  child: child,
                ),
              );
            },
            child: _buildVoidScriptBox(),
          ),
          if (_purgeComplete)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SIGNAL PURGED. INTEGRITY STABILIZED.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: _returnReady
                        ? () {
                            Navigator.pushReplacementNamed(context, '/bridge');
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      foregroundColor: Colors.white70,
                    ),
                    child: Text(
                      _returnReady ? 'RETURN TO BRIDGE' : 'STABILIZING...',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreValueSlider() {
    return Column(
      children: [
        const Text(
          'CURRENT STRESS LOAD',
          style: TextStyle(color: Color(0xFF738678)),
        ),
        SizedBox(
          height: 200,
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: _initialStress,
              min: 1,
              max: 10,
              activeColor: Colors.amber,
              onChanged: (val) => setState(() => _initialStress = val),
            ),
          ),
        ),
        Text(
          '${_initialStress.toInt()}/10',
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildVoidScriptBox() {
    return SizedBox(
      width: 320,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          reverse: true,
          child: TextField(
            controller: textController,
            focusNode: _inputFocusNode,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Write what you're ready to release...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: const Color(0xff0d0d20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VortexPainter extends CustomPainter {
  final double rotation;

  VortexPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.45;

    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: 2 * pi,
      colors: [
        Colors.black,
        Colors.deepPurple.withOpacity(0.4),
        Colors.black,
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(rotation * 2 * pi),
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);

    final corePaint = Paint()
      ..color = Colors.black
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(center, radius * 0.25, corePaint);
  }

  @override
  bool shouldRepaint(covariant VortexPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

class ShatterPainter extends CustomPainter {
  ShatterPainter({required this.progress, required this.offsets});

  final double progress;
  final List<Offset> offsets;

  @override
  void paint(Canvas canvas, Size size) {
    if (offsets.isEmpty) return;
    final paint = Paint()..color = Colors.amber.withOpacity(1.0 - progress);
    for (final offset in offsets) {
      final toCenter = Offset(-offset.dx, -offset.dy);
      final distance = toCenter.distance;
      final unit = distance == 0.0
          ? Offset.zero
          : Offset(toCenter.dx / distance, toCenter.dy / distance);
      final tangent = Offset(-unit.dy, unit.dx);

      // Protocol 12: centripetal pull to Offset(0, 0) plus tangential drift.
      final centripetal = Offset(toCenter.dx * progress, toCenter.dy * progress);
      final turn = sin(progress * 6 * pi);
      final tangential = Offset(
        tangent.dx * distance * 0.25 * (1.0 - progress) * turn,
        tangent.dy * distance * 0.25 * (1.0 - progress) * turn,
      );
      final pos = Offset(
        offset.dx + centripetal.dx + tangential.dx,
        offset.dy + centripetal.dy + tangential.dy,
      );
      final particleSize = 2.4 * (1.0 - progress);
      canvas.drawCircle(pos, particleSize.clamp(0.0, 2.4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
