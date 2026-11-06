import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:anxiety_anchor/audio/audio_halt.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({
    super.key,
    required this.track,
    required this.title,
  });

  final String track;
  final String title;

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSubscription;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
    _playerSubscription = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (aegisLifecycleSilencesAudio(state)) {
      unawaited(_haltPlayback());
    }
  }

  Future<void> _haltPlayback({bool notify = true}) async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.stop();
    } catch (_) {}
    _isPlaying = false;
    if (notify && mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerSubscription?.cancel();
    unawaited(_haltPlayback(notify: false).whenComplete(_player.dispose));
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.play(AssetSource('audio/${widget.track}.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF003366),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              _isPlaying ? 'Playing' : 'Paused',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _togglePlayback,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
              ),
              child: Text(_isPlaying ? 'Pause' : 'Play'),
            ),
          ],
        ),
      ),
    );
  }
}
