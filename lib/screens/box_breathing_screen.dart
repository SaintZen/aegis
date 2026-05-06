import 'dart:async';
import 'package:flutter/material.dart';

class BoxBreathingScreen extends StatefulWidget {
  const BoxBreathingScreen({super.key});

  @override
  State<BoxBreathingScreen> createState() => _BoxBreathingScreenState();
}

class _BoxBreathingScreenState extends State<BoxBreathingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _timer;
  int _currentPhase = 0; // 0: inhale, 1: hold in, 2: exhale, 3: hold out
  int _count = 4;
  bool _isRunning = false;
  int _cycles = 0;

  final List<Map<String, dynamic>> _phases = [
    {
      'name': 'Breathe In',
      'color': Colors.green,
      'instruction': 'Breathe in slowly through your nose',
    },
    {
      'name': 'Hold',
      'color': Colors.blue,
      'instruction': 'Hold your breath',
    },
    {
      'name': 'Breathe Out',
      'color': Colors.orange,
      'instruction': 'Breathe out slowly through your mouth',
    },
    {
      'name': 'Hold',
      'color': Colors.purple,
      'instruction': 'Hold at the bottom',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _isRunning = true;
      _currentPhase = 0;
      _count = 4;
      _cycles = 0;
    });
    _startPhase();
  }

  void _startPhase() {
    _count = 4;
    _animationController.reset();
    _animationController.forward();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_count > 0) {
        setState(() {
          _count--;
        });
      } else {
        _timer?.cancel();
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    if (_currentPhase < 3) {
      setState(() {
        _currentPhase++;
      });
      _startPhase();
    } else {
      // Completed one cycle
      setState(() {
        _cycles++;
        _currentPhase = 0; // Start over
      });
      _startPhase();
    }
  }

  void _stopBreathing() {
    _timer?.cancel();
    _animationController.stop();
    _animationController.reset();
    setState(() {
      _isRunning = false;
      _currentPhase = 0;
      _count = 4;
      _cycles = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phases[_currentPhase];
    final phaseColor = phase['color'] as Color;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Box Breathing'),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    phase['name'] as String,
                    style: TextStyle(
                      color: phaseColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    phase['instruction'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            // Visual breathing guide - expanding/contracting box
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // Calculate size based on phase
                    double size;
                    if (_currentPhase == 0) {
                      // Inhale - expand
                      size = 100 + (_animationController.value * 150);
                    } else if (_currentPhase == 1) {
                      // Hold in - stay large
                      size = 250;
                    } else if (_currentPhase == 2) {
                      // Exhale - contract
                      size = 250 - (_animationController.value * 150);
                    } else {
                      // Hold out - stay small
                      size = 100;
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Countdown number
                        Text(
                          '$_count',
                          style: TextStyle(
                            color: phaseColor,
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Breathing box visual
                        Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: phaseColor.withOpacity(0.3),
                            border: Border.all(
                              color: phaseColor,
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              _currentPhase == 0
                                  ? Icons.arrow_upward
                                  : _currentPhase == 2
                                      ? Icons.arrow_downward
                                      : Icons.pause,
                              color: phaseColor,
                              size: 60,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Cycle counter
                        Text(
                          'Cycle: $_cycles',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            
            // Control button
            Container(
              padding: const EdgeInsets.all(24),
              child: _isRunning
                  ? ElevatedButton.icon(
                      onPressed: _stopBreathing,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _startBreathing,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Breathing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                      ),
                    ),
            ),
            
            // Benefits text
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    'Box breathing activates your parasympathetic nervous system, helping you feel calm and in control. Follow the visual guide and count.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Dizzy? Stop and breathe normal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

