import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MercuryWell extends StatefulWidget {
  const MercuryWell({super.key});

  @override
  State<MercuryWell> createState() => _MercuryWellState();
}

class _MercuryWellState extends State<MercuryWell>
    with SingleTickerProviderStateMixin {
  bool _isActive = false;
  late AnimationController _pulseController;
  Timer? _hapticTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // 60 BPM thrum
    )..repeat(reverse: true);
  }

  void _startAnchoring() {
    setState(() => _isActive = true);
    // Low-frequency heartbeat thrum
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      HapticFeedback.heavyImpact();
    });
  }

  void _stopAnchoring() {
    setState(() => _isActive = false);
    _hapticTimer?.cancel();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _hapticTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startAnchoring(),
      onLongPressEnd: (_) => _stopAnchoring(),
      onLongPressCancel: () => _stopAnchoring(),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _isActive
                      ? Colors.cyan.withOpacity(0.8)
                      : Colors.blueGrey.withOpacity(0.4),
                  Colors.black,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      _isActive ? Colors.cyan.withOpacity(0.5) : Colors.transparent,
                  blurRadius: 20 * _pulseController.value,
                  spreadRadius: 5 * _pulseController.value,
                )
              ],
              border: Border.all(
                color: _isActive
                    ? Colors.cyan
                    : Colors.blueGrey.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _isActive ? 'ANCHORING' : 'SCAN',
                style: TextStyle(
                  color: _isActive ? Colors.cyan : Colors.blueGrey,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
