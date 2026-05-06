import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';

class VerbalDiaryScreen extends StatefulWidget {
  const VerbalDiaryScreen({super.key});

  @override
  State<VerbalDiaryScreen> createState() => _VerbalDiaryScreenState();
}

class _VerbalDiaryScreenState extends State<VerbalDiaryScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _lastFilePath;
  String _currentMood = 'Neutral';

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      await _startMoodTaggedRecording();
    } else {
      final path = await _audioRecorder.stop();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _lastFilePath = path;
      });
    }
  }

  Future<void> _startMoodTaggedRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required.')),
      );
      return;
    }

    final selected = await _showMoodPicker(context);
    if (selected == null) return;

    if (!mounted) return;
    setState(() => _currentMood = selected);

    HapticFeedback.lightImpact();
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${selected}_$timestamp.m4a';
    final filePath = '${directory.path}/$fileName';
    await _audioRecorder.start(const RecordConfig(), path: filePath);

    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _lastFilePath = null;
    });
  }

  void _shareWithPsychologist() {
    final path = _lastFilePath;
    if (path == null) return;
    _showExportConfirmation(context, path);
  }

  Future<void> _showExportConfirmation(BuildContext context, String filePath) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Export'),
        content: const Text(
          'No data is shared automatically. By clicking "Share", you are choosing to send this file to your provider.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Share.shareXFiles(
                [XFile(filePath)],
                text: 'My Verbal Diary for our next session.',
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Verbal Diary',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 16),
            _buildMoodSelector(),
            const SizedBox(height: 16),
            _isRecording
                ? const WaveformVisualizer()
                : const Icon(Icons.mic_none, size: 80, color: Colors.white24),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: _toggleRecording,
              child: CircleAvatar(
                radius: 40,
                backgroundColor:
                    _isRecording ? Colors.red : Colors.blueAccent,
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            if (_lastFilePath != null) ...[
              const SizedBox(height: 30),
              TextButton.icon(
                icon: const Icon(Icons.ios_share, color: Colors.amber),
                label: const Text(
                  'Upload to Psychologist',
                  style: TextStyle(color: Colors.amber),
                ),
                onPressed: _shareWithPsychologist,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    final moods = {
      'Calm': Icons.sentiment_satisfied,
      'Anxious': Icons.sensors,
      'Overwhelmed': Icons.cyclone,
      'Sad': Icons.sentiment_very_dissatisfied,
      'Panic': Icons.warning_amber,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: moods.entries.map((entry) {
        final isSelected = _currentMood == entry.key;
        final color = isSelected ? Colors.amber : Colors.white24;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            children: [
              IconButton(
                icon: Icon(entry.value, color: color),
                onPressed: () => setState(() => _currentMood = entry.key),
              ),
              Text(entry.key, style: TextStyle(color: color, fontSize: 10)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<String?> _showMoodPicker(BuildContext context) {
    final moods = ['Calm', 'Anxious', 'Overwhelmed', 'Sad', 'Panic'];
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select your mood'),
        children: moods
            .map(
              (mood) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, mood),
                child: Text(mood),
              ),
            )
            .toList(),
      ),
    );
  }
}

class WaveformVisualizer extends StatefulWidget {
  const WaveformVisualizer({super.key});

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              final phase = _controller.value * 2 * math.pi;
              final height = 14 + (22 * (0.5 + 0.5 * math.sin(phase + index)));
              return Container(
                width: 6,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
