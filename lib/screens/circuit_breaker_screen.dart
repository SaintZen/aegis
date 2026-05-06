import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class CircuitBreakerScreen extends StatefulWidget {
  const CircuitBreakerScreen({super.key});

  @override
  State<CircuitBreakerScreen> createState() => _CircuitBreakerScreenState();
}

class _CircuitBreakerScreenState extends State<CircuitBreakerScreen>
    with SingleTickerProviderStateMixin {
  bool _showLever = false;
  double _leverPos = 0.0;
  bool _isFlickering = false;
  double _initialLoad = 5.0;
  int _secondsRemaining = 60;
  late final AnimationController _leverReturnController;
  late final Animation<double> _leverReturnAnimation;
  double _leverReturnStart = 0.0;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _calculateTimerDuration(_initialLoad);
    _leverReturnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _leverReturnAnimation = CurvedAnimation(
      parent: _leverReturnController,
      curve: Curves.easeOut,
    )..addListener(() {
        setState(() {
          _leverPos =
              (_leverReturnStart * (1 - _leverReturnAnimation.value)).clamp(
            0.0,
            1.0,
          );
        });
      });
  }

  void _navigateToLever() {
    setState(() => _showLever = true);
  }

  Future<void> _tripBreaker() async {
    setState(() => _isFlickering = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _isFlickering = false);
    _animateLeverBack();
    if (!mounted) return;
    await Navigator.pushNamed(
      context,
      '/blackout',
      arguments: {
        'initialLoad': _initialLoad,
        'durationSeconds': _secondsRemaining,
      },
    );
  }

  int _calculateTimerDuration(double load) {
    final clampedLoad = load.clamp(1.0, 10.0);
    final scaled = (clampedLoad - 1) / 9;
    return (30 + (scaled * 150)).round();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    final paddedSeconds = remaining.toString().padLeft(2, '0');
    if (minutes == 0) {
      return '${remaining}s';
    }
    return '$minutes:$paddedSeconds';
  }

  void _animateLeverBack() {
    _leverReturnStart = _leverPos;
    _leverReturnController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      _showLever ? _buildLeverPlaceholder() : _buildExplanationScreen(),
                ),
              ),
            ),
            if (_isFlickering)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(color: Colors.white.withOpacity(0.85)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationScreen() {
    return Stack(
      children: [
        _buildExplanationContent(),
        Positioned(
          top: 40,
          right: 20,
          child: TextButton(
            onPressed: _navigateToLever,
            child: Text(
              'SKIP BRIEFING',
              style: TextStyle(
                color: const Color(0xFF738678).withOpacity(0.6),
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.bolt,
          color: Color(0xFF738678),
          size: 50,
        ),
        const SizedBox(height: 20),
        const Text(
          'CIRCUIT BREAKER ACTIVATED',
          style: TextStyle(
            color: Color(0xFF738678),
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'Use this when the digital world feels too loud. '
            'Tripping the breaker will force a ${_formatDuration(_secondsRemaining)} blackout '
            'to reset your focus.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
        ),
        OutlinedButton(
          onPressed: _navigateToLever,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF738678)),
          ),
          child: const Text(
            'EMBRACE THE SILENCE',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildLeverPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPowerLoadSlider(),
        const SizedBox(height: 16),
        const Text(
          'PULL THE LEVER',
          style: TextStyle(
            color: Color(0xFF738678),
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onVerticalDragUpdate: (details) {
            setState(() {
              _leverPos += details.delta.dy / 400;
              _leverPos = _leverPos.clamp(0.0, 1.0);

              if (_leverPos > 0.8) {
                HapticFeedback.heavyImpact();
              } else if (_leverPos > 0.2) {
                HapticFeedback.lightImpact();
              }
            });
          },
          onVerticalDragEnd: (_) {
            if (_leverPos >= 0.95) {
              _tripBreaker();
            } else {
              _animateLeverBack();
            }
          },
          child: CustomPaint(
            painter: IndustrialLeverPainter(progress: _leverPos),
            size: const Size(120, 320),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Trip the breaker to trigger a ${_formatDuration(_secondsRemaining)} blackout.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 28),
        OutlinedButton(
          onPressed: () => setState(() => _showLever = false),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF738678)),
          ),
          child: const Text(
            'BACK',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPowerLoadSlider() {
    return Column(
      children: [
        const Text(
          'DIAGNOSE SYSTEM LOAD',
          style: TextStyle(
            color: Color(0xFF738678),
            letterSpacing: 2,
          ),
        ),
        SizedBox(
          height: 180,
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: _initialLoad,
              min: 1,
              max: 10,
              activeColor: Colors.amber,
              onChanged: (val) => setState(() {
                _initialLoad = val;
                _secondsRemaining = _calculateTimerDuration(val);
              }),
            ),
          ),
        ),
        Text(
          'CURRENT LOAD: ${_initialLoad.toInt()}/10',
          style: const TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'BLACKOUT: ${_secondsRemaining}s',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _leverReturnController.dispose();
    super.dispose();
  }
}

class IndustrialLeverPainter extends CustomPainter {
  IndustrialLeverPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    final leverPaint = Paint()
      ..color = const Color(0xFF738678)
      ..style = PaintingStyle.fill;
    final knobPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.4, 0, size.width * 0.2, size.height),
      const Radius.circular(24),
    );
    canvas.drawRRect(trackRect, trackPaint);

    final knobY = size.height * progress;
    final leverStart = Offset(size.width * 0.5, 8);
    final leverEnd = Offset(size.width * 0.5, knobY.clamp(30, size.height - 30));
    canvas.drawLine(
      leverStart,
      leverEnd,
      leverPaint
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    canvas.drawCircle(leverEnd, 18, leverPaint);
    canvas.drawCircle(leverEnd, 8, knobPaint);
  }

  @override
  bool shouldRepaint(covariant IndustrialLeverPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class BlackoutCountdownScreen extends StatefulWidget {
  const BlackoutCountdownScreen({
    super.key,
    required this.initialLoad,
    required this.durationSeconds,
  });

  final double initialLoad;
  final int durationSeconds;

  @override
  State<BlackoutCountdownScreen> createState() =>
      _BlackoutCountdownScreenState();
}

class _BlackoutCountdownScreenState extends State<BlackoutCountdownScreen>
    with SingleTickerProviderStateMixin {
  late int _secondsLeft;
  Timer? _timer;
  late final AnimationController _pulseController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.durationSeconds;
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation =
        Tween<double>(begin: 0.2, end: 0.9).animate(_pulseController);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        _onTimerComplete();
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  void _onTimerComplete() {
    Navigator.pushReplacementNamed(
      context,
      '/success',
      arguments: {
        'tool': 'Circuit Breaker',
        'initialStressLevel': widget.initialLoad,
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF1B241E),
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'STATUS: CIRCUIT BREAKER TRIPPED',
                style: _techHeaderStyle(),
              ),
              Text(
                'MODE: SYSTEM BLACKOUT',
                style: _techSubHeaderStyle(),
              ),
              const SizedBox(height: 50),
              _buildBlackholeVisual(),
              const SizedBox(height: 50),
              Text(
                'RECOVERY IN PROGRESS...',
                style: _xanaduFadingStyle(),
              ),
              const SizedBox(height: 16),
              _buildTimerDisplay(),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _techHeaderStyle() {
    return const TextStyle(
      color: Color(0xFF738678),
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 3,
    );
  }

  TextStyle _techSubHeaderStyle() {
    return const TextStyle(
      color: Color(0xFF738678),
      fontSize: 12,
      fontWeight: FontWeight.w300,
      letterSpacing: 2,
    );
  }

  TextStyle _xanaduFadingStyle() {
    return TextStyle(
      color: const Color(0xFF738678).withOpacity(0.6),
      fontSize: 12,
      letterSpacing: 2,
    );
  }

  Widget _buildBlackholeVisual() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glow = _glowAnimation.value;
        return Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Colors.black,
                Color(0xFF1B241E),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF738678).withOpacity(0.2 * glow),
                blurRadius: 30 * glow,
                spreadRadius: 4 * glow,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildTimerDisplay() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(_secondsLeft),
              style: TextStyle(
                fontSize: 84,
                fontWeight: FontWeight.w100,
                color: const Color(0xFF738678).withOpacity(0.9),
                fontFamily: 'Courier',
                shadows: [
                  Shadow(
                    blurRadius: 25 * _glowAnimation.value,
                    color: const Color(0xFF738678)
                        .withOpacity(0.4 * _glowAnimation.value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'RECALIBRATING SYSTEM',
              style: TextStyle(
                letterSpacing: 4,
                fontSize: 12,
                color: const Color(0xFF738678).withOpacity(0.6),
              ),
            ),
          ],
        );
      },
    );
  }
}
