import 'dart:async';

import 'package:flutter/material.dart';

class BreathingGuideScreen extends StatefulWidget {
  const BreathingGuideScreen({super.key});

  @override
  State<BreathingGuideScreen> createState() => _BreathingGuideScreenState();
}

class _BreathingGuideScreenState extends State<BreathingGuideScreen>
    with SingleTickerProviderStateMixin {
  int _counter = 4;
  String _phase = 'Breathe IN';
  Timer? _timer;
  bool _isActive = false;
  late final AnimationController _scaleController;

  void _startBreathing() {
    if (_isActive) return;
    setState(() => _isActive = true);
    _updateCircleScale();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_counter > 1) {
          _counter--;
        } else {
          if (_phase == 'Breathe IN') {
            _phase = 'HOLD';
            _counter = 4;
          } else if (_phase == 'HOLD') {
            _phase = 'Breathe OUT';
            _counter = 4;
          } else {
            _phase = 'Breathe IN';
            _counter = 4;
          }
          _updateCircleScale();
        }
      });
    });
  }

  void _stopBreathing() {
    _timer?.cancel();
    setState(() => _isActive = false);
    _scaleController
      ..stop()
      ..value = 1.0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
      lowerBound: 1.0,
      upperBound: 2.5,
    )..value = 1.0;
  }

  void _updateCircleScale() {
    if (_phase == 'Breathe IN') {
      _scaleController.animateTo(
        2.5,
        duration: const Duration(seconds: 4),
      );
    } else if (_phase == 'Breathe OUT') {
      _scaleController.animateTo(
        1.0,
        duration: const Duration(seconds: 4),
      );
    } else {
      _scaleController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[400],
      appBar: AppBar(
        title: const Text('Emergency Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "Take a moment to breathe. You're not alone.",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lungs, size: 50, color: Colors.pinkAccent),
                  const Text(
                    'Breathing Guide',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ScaleTransition(
                    scale: _scaleController,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.purple.withOpacity(0.5),
                      ),
                      child: Center(
                        child: Text(
                          '$_counter',
                          style: const TextStyle(
                            fontSize: 60,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _phase,
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _startBreathing,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                        ),
                        child: const Text('START'),
                      ),
                      ElevatedButton(
                        onPressed: _stopBreathing,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        child: const Text('STOP'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Chip(
              label: Text('💡 Tip: Breathe naturally - don\'t force it!'),
            ),
          ),
        ],
      ),
    );
  }
}
