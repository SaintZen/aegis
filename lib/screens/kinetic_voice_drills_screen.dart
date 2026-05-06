import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class KineticVoiceDrillsScreen extends StatefulWidget {
  const KineticVoiceDrillsScreen({super.key});

  @override
  State<KineticVoiceDrillsScreen> createState() =>
      _KineticVoiceDrillsScreenState();
}

class _KineticVoiceDrillsScreenState extends State<KineticVoiceDrillsScreen> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<Duration>? _positionSub;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  int _selectedIndex = 0;
  bool _isPlaying = false;
  bool _isPerimeterLocked = false;

  final List<_VoiceDrill> _drills = const [
    _VoiceDrill(
      title: 'Resilient Press',
      audioPath: 'assets/audio/kinetic/resilient_press.mp3',
      imagePath: 'assets/images/kinetic/resilient_press.png',
      subtitle: 'Isometric grounding: palms or feet press.',
      script: 'Press palms together, or press feet firmly into the floor. '
          'Hold the tension for 5–10 seconds. Breathe. Release slowly on an exhale. '
          'Repeat 3–5 times.',
    ),
    _VoiceDrill(
      title: 'Butterfly Hug',
      audioPath: 'assets/audio/kinetic/butterfly_hug.mp3',
      imagePath: 'assets/images/kinetic/butterfly_hug.png',
      subtitle: 'Bilateral taps to settle racing thoughts.',
      script: 'Cross your arms over your chest. Alternately tap each shoulder '
          'with the opposite hand—left tap, right tap—in a steady rhythm. '
          'Keep it gentle. Match your breath. Continue until the mind settles.',
    ),
    _VoiceDrill(
      title: 'Neck & Jaw Release',
      audioPath: 'assets/audio/kinetic/neck_jaw_release.mp3',
      imagePath: 'assets/images/kinetic/neck_jaw_release.png',
      subtitle: 'Vagus reset to release the freeze response.',
      script: 'Let your jaw go slack. Gently tilt your head to one side, '
          'hold for a breath, then the other. Roll shoulders back and down. '
          'Take a long exhale. Repeat 2–3 times.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _playerSub = _player.playerStateStream.listen((state) {
      final playing = state.playing;
      if (!mounted) return;
      setState(() => _isPlaying = playing);
      if (playing) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
      if (state.processingState == ProcessingState.completed) {
        WakelockPlus.disable();
      }
    });
    _durationSub = _player.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration ?? Duration.zero);
    });
    _positionSub = _player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _player.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _loadDrill(int index) async {
    setState(() {
      _selectedIndex = index;
      _position = Duration.zero;
    });
    await _player.setAsset(_drills[index].audioPath);
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }
    if (_player.processingState == ProcessingState.idle) {
      await _loadDrill(_selectedIndex);
    }
    await _player.play();
  }

  double _progressValue() {
    if (_duration.inMilliseconds == 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Voice-Guided Drills'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormPreview(),
              const SizedBox(height: 20),
              _buildCircuitBreakerToggle(),
              const SizedBox(height: 20),
              _buildDrillPicker(),
              const SizedBox(height: 24),
              _buildPlayerControls(),
              const SizedBox(height: 12),
              _buildProgressText(),
            ],
          ),
        ),
      ),
    );
  }

  /// Visual guide + script for the selected drill. "Form" = posture/position.
  Widget _buildFormPreview() {
    final drill = _drills[_selectedIndex];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Visual + Script',
            style: TextStyle(
              color: Colors.white70,
              letterSpacing: 1.2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Image shows form; script is your written guide.',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Image.asset(
            drill.imagePath,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox(
              height: 120,
              child: Center(child: Icon(Icons.image_not_supported, color: Colors.white38)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            drill.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              drill.script,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrillPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'DRILLS',
          style: TextStyle(
            color: Colors.white70,
            letterSpacing: 1.4,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_drills.length, (index) {
          final selected = index == _selectedIndex;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: ElevatedButton(
              onPressed: () => _loadDrill(index),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selected ? Colors.deepOrange : Colors.white12,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(_drills[index].title),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCircuitBreakerToggle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0000),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF0000), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'PERIMETER CIRCUIT BREAKER',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFFA500),
              fontFamily: 'RobotoMono',
              letterSpacing: 1.8,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Switch(
            value: _isPerimeterLocked,
            onChanged: _togglePerimeter,
            activeThumbColor: const Color(0xFFFF0000),
            inactiveTrackColor: Colors.white10,
          ),
          Text(
            _isPerimeterLocked ? 'STATUS: SEVERED' : 'STATUS: OPEN',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'RobotoMono',
              letterSpacing: 1.4,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _togglePerimeter(bool value) {
    setState(() => _isPerimeterLocked = value);
    if (value) {
      Navigator.pushNamed(context, '/circuit-breaker');
    }
  }

  Widget _buildPlayerControls() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: _progressValue(),
              strokeWidth: 6,
              color: Colors.deepOrange,
              backgroundColor: Colors.white12,
            ),
          ),
          IconButton(
            iconSize: 42,
            onPressed: _togglePlayback,
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: Colors.deepOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressText() {
    String format(Duration d) {
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }

    return Center(
      child: Text(
        '${format(_position)} / ${format(_duration)}',
        style: const TextStyle(color: Colors.white54),
      ),
    );
  }
}

class _VoiceDrill {
  const _VoiceDrill({
    required this.title,
    required this.audioPath,
    required this.imagePath,
    required this.subtitle,
    required this.script,
  });

  final String title;
  final String audioPath;
  final String imagePath;
  final String subtitle;
  final String script;
}
