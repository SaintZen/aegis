import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:anxiety_anchor/models/exercise.dart';

class UnifiedExerciseScreen extends StatefulWidget {
  final Exercise exercise;
  final String? currentInstruction; // For exercises with dynamic instructions

  const UnifiedExerciseScreen({
    super.key,
    required this.exercise,
    this.currentInstruction,
  });

  @override
  State<UnifiedExerciseScreen> createState() => _UnifiedExerciseScreenState();
}

class _UnifiedExerciseScreenState extends State<UnifiedExerciseScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _hasVibrationPermission = false;
  bool _voiceEnabled = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.exercise.durationSeconds;
    _checkVibrationPermission();
  }

  Future<void> _checkVibrationPermission() async {
    if (await Vibration.hasVibrator() ?? false) {
      setState(() {
        _hasVibrationPermission = true;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    
    // For exercises without timers, just show completion
    if (widget.exercise.durationSeconds == 0) {
      _showCompletionDialog();
      return;
    }

    setState(() {
      _isRunning = true;
      _isPaused = false;
      _progress = 0.0;
    });

    final totalSeconds = widget.exercise.durationSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          _progress = 1.0 - (_remainingSeconds / totalSeconds);
        });

        // For "The Shake Out" exercise, vibrate periodically
        if (widget.exercise.title == 'The "Shake Out"' && _hasVibrationPermission) {
          // Vibrate every 5 seconds for 30-second exercise
          if (_remainingSeconds % 5 == 0 && _remainingSeconds > 0) {
            Vibration.vibrate(duration: 200);
          }
        }

        // Voice guidance (if enabled)
        if (_voiceEnabled) {
          // Speak countdown at key intervals
          if (_remainingSeconds == 10 || _remainingSeconds == 5 || _remainingSeconds == 1) {
            _speakInstruction('$_remainingSeconds seconds remaining');
          }
        }
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
          _progress = 1.0;
        });
        _showCompletionDialog();
      }
    });
  }

  void _speakInstruction(String text) {
    // TODO: Implement TTS when available
    // For now, this is a placeholder
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isPaused = true;
      _isRunning = false;
    });
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = widget.exercise.durationSeconds;
      _isRunning = false;
      _isPaused = false;
      _progress = 0.0;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text(
          'Exercise Complete!',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Great job! How are you feeling now?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _getCurrentInstruction() {
    return widget.currentInstruction ?? widget.exercise.instructions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(widget.exercise.title),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.exercise.title.contains('Shake')) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'If you feel faint, sit down and let go.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Voice Toggle Card
            Container(
              margin: const EdgeInsets.all(16),
              child: Card(
                color: Colors.grey[800],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.volume_up, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(
                            'Voice Guide',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _voiceEnabled,
                        onChanged: (value) {
                          setState(() {
                            _voiceEnabled = value;
                          });
                        },
                        activeThumbColor: Colors.amber,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Large Countdown Timer at Top (only show if exercise has duration)
            if (widget.exercise.durationSeconds > 0) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF738678).withOpacity(0.2),
                      Colors.black,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      color: Color(0xFF738678),
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 8,
                    ),
                  ),
                ),
              ),

              // Progress Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey[700],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_progress * 100).toInt()}% Complete',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              // For exercises without timer, show title instead
              Container(
                padding: const EdgeInsets.all(24),
                child: Text(
                  widget.exercise.title,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            // Specific Instruction Text
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: Colors.grey[800],
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Instructions:',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _getCurrentInstruction(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Control Buttons (only show if exercise has duration)
            if (widget.exercise.durationSeconds > 0)
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isRunning && !_isPaused)
                      ElevatedButton.icon(
                        onPressed: _startTimer,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      )
                    else if (_isPaused)
                      ElevatedButton.icon(
                        onPressed: _resumeTimer,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Resume'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _pauseTimer,
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
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

