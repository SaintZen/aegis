import 'dart:async';

import 'package:flutter/material.dart';

import 'package:anxiety_anchor/services/calibration_service.dart';

class RescueBreathingScreen extends StatefulWidget {
  const RescueBreathingScreen({super.key, this.preset});

  final String? preset;

  @override
  State<RescueBreathingScreen> createState() => _RescueBreathingScreenState();
}

class _RescueBreathingScreenState extends State<RescueBreathingScreen>
    with TickerProviderStateMixin {
  late AnimationController _sizeController;
  int _counter = 4;
  String _phase = 'Breathe IN';
  Timer? _timer;

  final List<Map<String, dynamic>> _styles = [
    {
      'name': 'Square',
      'in': 4,
      'hold1': 4,
      'out': 4,
      'hold2': 4,
      'color': Colors.blue
    },
    {
      'name': '4-7-8',
      'in': 4,
      'hold1': 7,
      'out': 8,
      'hold2': 0,
      'color': Colors.purple
    },
    {
      'name': 'Anchor',
      'in': 5,
      'hold1': 5,
      'out': 5,
      'hold2': 5,
      'color': Colors.redAccent
    },
    {
      'name': 'Cooling',
      'in': 4,
      'hold1': 0,
      'out': 6,
      'hold2': 0,
      'color': Colors.teal
    },
    {
      'name': 'Rapid',
      'in': 2,
      'hold1': 0,
      'out': 4,
      'hold2': 0,
      'color': Colors.orange
    },
  ];

  int _currentStyleIndex = 0;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _currentStyleIndex = _presetToIndex(widget.preset);
    CalibrationService.getReducedMotion().then((v) {
      if (mounted) setState(() => _reducedMotion = v);
    });
    _sizeController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _isAnchorStyle ? 20 : 4),
    )..repeat(reverse: true);
    _startTimer();
  }

  void _maybeRecreateSizeController() {
    final anchorDuration = const Duration(seconds: 20);
    final defaultDuration = const Duration(seconds: 4);
    final wanted =
        _isAnchorStyle ? anchorDuration : defaultDuration;
    if (_sizeController.duration != wanted) {
      _sizeController.dispose();
      _sizeController = AnimationController(
        vsync: this,
        duration: wanted,
      )..repeat(reverse: true);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    final style = _styles[_currentStyleIndex];
    _counter = style['in'] as int;
    _phase = 'Breathe IN';

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_counter > 1) {
          _counter--;
        } else {
          _switchPhase(style);
        }
      });
    });
  }

  void _switchPhase(Map<String, dynamic> style) {
    if (_phase == 'Breathe IN') {
      if (style['hold1'] > 0) {
        _phase = 'HOLD';
        _counter = style['hold1'] as int;
      } else {
        _phase = 'Breathe OUT';
        _counter = style['out'] as int;
      }
    } else if (_phase == 'HOLD') {
      _phase = 'Breathe OUT';
      _counter = style['out'] as int;
    } else if (_phase == 'Breathe OUT') {
      if (style['hold2'] > 0) {
        _phase = 'REST';
        _counter = style['hold2'] as int;
      } else {
        _phase = 'Breathe IN';
        _counter = style['in'] as int;
      }
    } else {
      _phase = 'Breathe IN';
      _counter = style['in'] as int;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sizeController.dispose();
    super.dispose();
  }

  bool get _isAnchorStyle => _currentStyleIndex == 2;

  @override
  Widget build(BuildContext context) {
    final currentStyle = _styles[_currentStyleIndex];
    final color = currentStyle['color'] as Color;

    return DefaultTabController(
      length: 5,
      initialIndex: _currentStyleIndex,
      child: Scaffold(
        backgroundColor: _isAnchorStyle
            ? null
            : Color.alphaBlend(
                Colors.black.withOpacity(0.7),
                color,
              ),
        body: _isAnchorStyle
            ? _buildAnchorView()
            : _buildStandardView(color),
      ),
    );
  }

  Widget _buildStandardView(Color color) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              isScrollable: true,
              onTap: (index) {
                setState(() {
                  _currentStyleIndex = index;
                  _maybeRecreateSizeController();
                  _startTimer();
                });
              },
              tabs: _styles.map((s) => Tab(text: s['name'] as String)).toList(),
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _phase,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _sizeController,
                  builder: (context, child) {
                    final size = _reducedMotion
                        ? 225.0
                        : 200 + (_sizeController.value * 50);
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.5),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '$_counter',
                          style: const TextStyle(
                            fontSize: 72,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 60),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Focus on the number. Let the circle guide your lungs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnchorView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0E14),
            Color(0xFF1A202C),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              onTap: (index) {
                setState(() {
                  _currentStyleIndex = index;
                  _maybeRecreateSizeController();
                  _startTimer();
                });
              },
              tabs: _styles.map((s) => Tab(text: s['name'] as String)).toList(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final anchorSize = constraints.maxHeight * 0.40;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          _phase,
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white70,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 32),
                        AnimatedBuilder(
                          animation: _sizeController,
                          builder: (context, child) {
                            final glowRadius = _reducedMotion
                                ? 42.0
                                : 24 + (_sizeController.value * 36);
                            final spreadRadius = _reducedMotion
                                ? 4.0
                                : _sizeController.value * 8;
                            return Container(
                              width: anchorSize,
                              height: anchorSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.12),
                                    blurRadius: glowRadius,
                                    spreadRadius: spreadRadius,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF3D4A5C).withOpacity(0.4),
                                    blurRadius: glowRadius * 0.5,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF4A5568),
                                      Color(0xFF2D3748),
                                      Color(0xFF1A202C),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFF718096).withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.anchor,
                                    size: anchorSize * 0.6,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 80),
                        const Text(
                          'ANCHOR ME NOW',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white54,
                            letterSpacing: 4.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_counter',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white38,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _presetToIndex(String? preset) {
    switch (preset) {
      case '478':
        return 1;
      case 'anchor':
        return 2;
      case 'cooling':
        return 3;
      default:
        return 0;
    }
  }
}
