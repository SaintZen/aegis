import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

class SystemInitializationScreen extends StatefulWidget {
  const SystemInitializationScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SystemInitializationScreen> createState() =>
      _SystemInitializationScreenState();
}

class _SystemInitializationScreenState extends State<SystemInitializationScreen> {
  static const String _introText =
      'Aegis System online. Calibrating somatic sensors. Stay grounded.';

  final AudioPlayer _player = AudioPlayer();
  Timer? _hapticTimer;
  bool _audioReady = false;
  bool _audioDone = false;
  bool _requesting = false;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _startHandshake();
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startHandshake() async {
    try {
      await _player.setAsset('assets/audio/affirmations/system/sys_on.mp3');
      setState(() => _audioReady = true);
      _startCalibrationHum();
      await _player.play();
      await _player.processingStateStream.firstWhere(
        (state) => state == ProcessingState.completed,
      );
    } catch (_) {
      // Fallback if audio missing: continue flow.
    } finally {
      _stopCalibrationHum();
      if (mounted) {
        setState(() => _audioDone = true);
      }
    }
  }

  void _startCalibrationHum() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) return;
    Vibration.vibrate(
      pattern: const [0, 12, 13],
      intensities: const [128, 0, 128],
      repeat: 1,
    );
    _hapticTimer?.cancel();
    _hapticTimer = Timer(const Duration(seconds: 3), _stopCalibrationHum);
  }

  void _stopCalibrationHum() {
    Vibration.cancel();
    _hapticTimer?.cancel();
    _hapticTimer = null;
  }

  Future<void> _requestPermissions() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    final notification = await Permission.notification.request();
    final sensors = await Permission.sensors.request();
    final granted = notification.isGranted || sensors.isGranted;
    if (mounted) {
      setState(() {
        _permissionsGranted = granted;
        _requesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text(
                'SYSTEM INITIALIZATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _introText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 28),
              if (!_audioReady)
                const LinearProgressIndicator(color: Colors.white54),
              const Spacer(),
              Text(
                'I need access to your haptics to anchor your nervous system.',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  height: 1.6,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 16),
              if (_audioDone)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _requesting ? null : _requestPermissions,
                    child: Text(
                      _permissionsGranted
                          ? 'PERMISSIONS GRANTED'
                          : 'GRANT PERMISSIONS',
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _audioDone ? widget.onComplete : null,
                  child: const Text('CONTINUE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
