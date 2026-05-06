import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:anxiety_anchor/services/calibration_service.dart';
import 'package:anxiety_anchor/services/aegis_log_service.dart';
import 'package:anxiety_anchor/services/usage_log_service.dart';
import 'package:anxiety_anchor/services/haptics/somatic_controller.dart';
import 'package:anxiety_anchor/screens/resource_detail_screen.dart';

class FrostScreen extends StatefulWidget {
  const FrostScreen({super.key});

  @override
  State<FrostScreen> createState() => _FrostScreenState();
}

class _FrostScreenState extends State<FrostScreen> {
  static const double _scrapeTriggerDistance = 2.0;
  List<Offset?> points = [];
  final List<String> _frostImages = List.generate(
    19,
    (i) =>
        'assets/images/frost/frost_screen_${(i + 1).toString().padLeft(2, '0')}.jpg',
  );
  int _currentImageIndex = 0;
  double _frostOpacity = 0.9;
  bool _isScraping = false;
  final Stopwatch _scrapeStopwatch = Stopwatch();
  final SomaticController _somaticController = SomaticController();
  Offset? _lastScrapePosition;
  final List<_Spark> _sparks = [];
  final math.Random _sparkRandom = math.Random();
  bool _showKillFlash = false;

  @override
  void initState() {
    super.initState();
    _currentImageIndex = math.Random().nextInt(_frostImages.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'FROST SCRAPE',
          style: TextStyle(letterSpacing: 2, fontSize: 14),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ResourceDetailScreen(
                    initialTitle: 'The Somatic Reset (The Frost Screen)',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New frost plate (random image)',
            onPressed: _resetFrostWithNewImage,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFrostSafetyWarning(),
          Expanded(
            child: GestureDetector(
              onDoubleTap: _cycleFrostImage,
              onLongPress: _resetFrostEffect,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildFrostLayer(),
                  if (_showKillFlash)
                    Positioned.fill(
                      child: Container(color: Colors.red),
                    ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: SafeArea(
                      child: _buildFrostResetTab(),
                    ),
                  ),
                ],
              ),
            ),
        ),
        ],
      ),
    );
  }

  Widget _buildFrostSafetyWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.amber.withOpacity(0.15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cold exposure tools should be used with caution. Do not use if you '
              'have Raynaud\'s disease, cold urticaria, or any cardiovascular '
              'conditions without consulting a physician.',
              style: TextStyle(
                color: Colors.amber.shade100,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _emergencyStop() async {
    await _somaticController.emergencyStop();
    await AegisLogService.logEntry(
      toolName: 'Frost Scraper',
      status: 'Aborted',
    );
    if (!mounted) return;
    setState(() => _showKillFlash = true);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _buildFrostLayer() {
    return Stack(
      children: [
        Image.asset(
          _frostImages[_currentImageIndex],
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              Container(color: const Color(0xFF001219)),
        ),
        Listener(
          onPointerDown: (_) {
            if (CalibrationService.hapticIntensitySync > 0) {
              CalibrationService.fireTacticalFeedback(fallback: HapticIntensity.medium);
            }
          },
          onPointerMove: (event) {
            if (event.delta.distance <= 0.5) return;
            final renderBox = context.findRenderObject() as RenderBox;
            final localPos = renderBox.globalToLocal(event.position);
            setState(() {
              points.add(localPos);
              _emitSparksAt(localPos);
            });
            _handleScrapeFeedback(localPos);
          },
          onPointerUp: (_) => _stopAllFeedback(),
          onPointerCancel: (_) => _stopAllFeedback(),
          child: CustomPaint(
            painter: FrostPainter(
              points: points,
              sparks: _sparks,
              frostOpacity: _frostOpacity,
            ),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }

  void _cycleFrostImage() {
    setState(() {
      _currentImageIndex = (_currentImageIndex + 1) % _frostImages.length;
      _frostOpacity = 0.0;
      points.clear();
      _sparks.clear();
      _lastScrapePosition = null;
    });
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() => _frostOpacity = 0.9);
    });
  }

  /// Clears scrape paths and restores full frost on the **current** image.
  void _resetFrostEffect() {
    setState(() {
      points.clear();
      _sparks.clear();
      _lastScrapePosition = null;
      _frostOpacity = 0.9;
    });
  }

  /// Picks a random index in `[0, n)` other than [exclude] when `n > 1`.
  int _randomIndexExcluding(int exclude) {
    final n = _frostImages.length;
    if (n <= 1) return 0;
    var r = math.Random().nextInt(n - 1);
    if (r >= exclude) r += 1;
    return r;
  }

  /// Clear scrapes + new plate that is never the same asset as the current one.
  void _resetFrostWithDifferentImage() {
    setState(() {
      points.clear();
      _sparks.clear();
      _lastScrapePosition = null;
      _frostOpacity = 0.9;
      _currentImageIndex = _randomIndexExcluding(_currentImageIndex);
    });
  }

  /// New random background + clear scrapes (app bar refresh).
  void _resetFrostWithNewImage() {
    setState(() {
      points.clear();
      _sparks.clear();
      _lastScrapePosition = null;
      _frostOpacity = 0.9;
      _currentImageIndex = _randomIndexExcluding(_currentImageIndex);
    });
  }

  Widget _buildFrostResetTab() {
    return Material(
      color: const Color(0xFF0A0A0A).withOpacity(0.72),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _resetFrostWithDifferentImage();
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            'RESET',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontFamily: 'RobotoMono',
              fontSize: 9,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startScrapeAudio() async {
    try {
      await _somaticController.startFriction(
        velocity: _lastScrapePosition == null ? 0 : _scrapeTriggerDistance,
      );
      _isScraping = true;
      if (!_scrapeStopwatch.isRunning) {
        _scrapeStopwatch
          ..reset()
          ..start();
      }
    } catch (e) {
      debugPrint('Scrape audio play failed: $e');
    }
  }

  Future<void> _stopScrapeAudio() async {
    if (!_isScraping) return;
    try {
      await _somaticController.stopFriction();
    } catch (e) {
      debugPrint('Scrape audio stop failed: $e');
    } finally {
      _isScraping = false;
      if (_scrapeStopwatch.isRunning) {
        _scrapeStopwatch.stop();
        final elapsed = _scrapeStopwatch.elapsed.inSeconds;
        _scrapeStopwatch.reset();
        unawaited(UsageLogService.logAnchorUsage(
          flavor: 'Scraping Ice',
          durationSeconds: elapsed == 0 ? 1 : elapsed,
        ));
      }
    }
  }

  void _emitSparksAt(Offset origin) {
    _sparks
      ..clear()
      ..addAll(List.generate(14, (_) {
        final dx = (_sparkRandom.nextDouble() - 0.5) * 24;
        final dy = (_sparkRandom.nextDouble() - 0.5) * 24;
        final radius = 1.5 + _sparkRandom.nextDouble() * 2.5;
        return _Spark(
          position: Offset(origin.dx + dx, origin.dy + dy),
          radius: radius,
          opacity: 0.9,
        );
      }));
  }

  void _handleScrapeFeedback(Offset current) {
    final last = _lastScrapePosition;
    _lastScrapePosition = current;
    if (last == null) return;
    final distance = (current - last).distance;
    if (distance < _scrapeTriggerDistance) {
      return;
    }
    _startScrapeAudio();
    _somaticController.startFriction(velocity: distance);
  }

  Future<void> _stopAllFeedback() async {
    if (mounted) {
      setState(() => points.add(null));
    }
    _stopScrapeVisuals();
    await _stopScrapeAudio();
    _lastScrapePosition = null;
  }

  void _stopScrapeVisuals() {
    if (_sparks.isEmpty) return;
    setState(_sparks.clear);
  }

  @override
  void dispose() {
    _somaticController.emergencyStop();
    _somaticController.dispose();
    super.dispose();
  }
}

class FrostPainter extends CustomPainter {
  final List<Offset?> points;
  final List<_Spark> sparks;
  final double frostOpacity;

  FrostPainter({
    required this.points,
    required this.sparks,
    required this.frostOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final icePaint = Paint()
      ..color = Colors.white.withOpacity(frostOpacity.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final scrapePaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 18.0;

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), icePaint);

    for (var i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, scrapePaint);
      }
    }
    canvas.restore();

    if (sparks.isNotEmpty) {
      final sparkPaint = Paint()..blendMode = BlendMode.plus;
      for (final spark in sparks) {
        sparkPaint.color = const Color(0xFFB8FFF8).withOpacity(spark.opacity);
        canvas.drawCircle(spark.position, spark.radius, sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(FrostPainter oldDelegate) => true;
}

class _Spark {
  _Spark({
    required this.position,
    required this.radius,
    required this.opacity,
  });

  final Offset position;
  final double radius;
  final double opacity;
}
