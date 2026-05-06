import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class Affirmation {
  final String text;
  final String category;
  final String audioPath;

  Affirmation({
    required this.text,
    required this.category,
    required this.audioPath,
  });
}

class AffirmationsLibraryScreen extends StatefulWidget {
  const AffirmationsLibraryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AffirmationsLibraryScreen> createState() =>
      _AffirmationsLibraryScreenState();
}

class _AffirmationsLibraryScreenState extends State<AffirmationsLibraryScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isGuidedModeActive = false;
  int _currentIndex = 0;
  Timer? _advanceTimer;
  StreamSubscription<PlayerState>? _playerSubscription;
  StreamSubscription<PlayerState>? _voiceTrackSubscription;
  late final AnimationController _animationController;

  final List<Affirmation> _affirmations = [
    // Self-Worth
    Affirmation(
      text: 'I am worthy of love and kindness, especially from myself.',
      category: 'Self-Worth',
      audioPath: 'assets/audio/vo_selfworth_01.mp3',
    ),
    Affirmation(
      text: 'I am enough, exactly as I am in this moment.',
      category: 'Self-Worth',
      audioPath: 'assets/audio/vo_selfworth_02.mp3',
    ),
    Affirmation(
      text: 'I deserve to treat myself with gentleness and compassion.',
      category: 'Self-Worth',
      audioPath: 'assets/audio/vo_selfworth_03.mp3',
    ),
    Affirmation(
      text: 'My worth is not determined by my productivity or achievements.',
      category: 'Self-Worth',
      audioPath: 'assets/audio/vo_selfworth_04.mp3',
    ),
    Affirmation(
      text: 'I am valuable simply because I exist.',
      category: 'Self-Worth',
      audioPath: 'assets/audio/vo_selfworth_05.mp3',
    ),
    // Strength
    Affirmation(
      text: 'I have survived difficult times before, and I will survive this.',
      category: 'Strength',
      audioPath: 'assets/audio/vo_strength_01.mp3',
    ),
    Affirmation(
      text: 'I am stronger than I feel right now.',
      category: 'Strength',
      audioPath: 'assets/audio/vo_strength_02.mp3',
    ),
    Affirmation(
      text: 'I have the capacity to handle whatever comes my way.',
      category: 'Strength',
      audioPath: 'assets/audio/vo_strength_03.mp3',
    ),
    Affirmation(
      text: 'Challenges help me grow and become more resilient.',
      category: 'Strength',
      audioPath: 'assets/audio/vo_strength_04.mp3',
    ),
    Affirmation(
      text: 'I can get through this moment, one breath at a time.',
      category: 'Strength',
      audioPath: 'assets/audio/vo_strength_05.mp3',
    ),
    // Anxiety
    Affirmation(
      text: 'This feeling is temporary, and it will pass.',
      category: 'Anxiety',
      audioPath: 'assets/audio/vo_anxiety_01.mp3',
    ),
    Affirmation(
      text: 'I am safe in this moment, right here, right now.',
      category: 'Anxiety',
      audioPath: 'assets/audio/vo_anxiety_02.mp3',
    ),
    Affirmation(
      text: 'Anxiety is a feeling, not a fact.',
      category: 'Anxiety',
      audioPath: 'assets/audio/vo_anxiety_03.mp3',
    ),
    Affirmation(
      text: 'I can observe my anxiety without being controlled by it.',
      category: 'Anxiety',
      audioPath: 'assets/audio/vo_anxiety_04.mp3',
    ),
    Affirmation(
      text: 'I have tools to help myself feel calmer.',
      category: 'Anxiety',
      audioPath: 'assets/audio/vo_anxiety_05.mp3',
    ),
    // Growth
    Affirmation(
      text: "I am making progress, even when it doesn't feel like it.",
      category: 'Growth',
      audioPath: 'assets/audio/vo_growth_01.mp3',
    ),
    Affirmation(
      text: 'Every small step I take matters.',
      category: 'Growth',
      audioPath: 'assets/audio/vo_growth_02.mp3',
    ),
    Affirmation(
      text: 'I can create space between myself and my worries.',
      category: 'Growth',
      audioPath: 'assets/audio/vo_growth_03.mp3',
    ),
    Affirmation(
      text: 'I am learning how to take care of myself with patience.',
      category: 'Growth',
      audioPath: 'assets/audio/vo_growth_04.mp3',
    ),
    Affirmation(
      text: 'Each breath I take is a step toward calm.',
      category: 'Growth',
      audioPath: 'assets/audio/vo_growth_05.mp3',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _playerSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        _advanceToNext();
      }
    });
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _playerSubscription?.cancel();
    _voiceTrackSubscription?.cancel();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildContent();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Affirmations'),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildGuidedToggle(),
        Expanded(child: _buildAffirmationList()),
      ],
    );
  }

  Widget _buildGuidedToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SwitchListTile(
        title: const Text('Studio Guidance'),
        subtitle: const Text('Plays a guided audio track for each affirmation'),
        value: _isGuidedModeActive,
        onChanged: (value) => _toggleGuidedMode(value),
      ),
    );
  }

  Widget _buildAffirmationList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _affirmations.length,
      itemBuilder: (context, index) {
        final affirmation = _affirmations[index];
        final isActive = index == _currentIndex;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: isActive ? 1.0 : 0.6,
          child: Card(
            color: Colors.white.withOpacity(0.05),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: Text(affirmation.text),
              subtitle: Text(affirmation.category),
              trailing: Icon(
                isActive ? Icons.play_arrow_rounded : Icons.arrow_forward_ios,
                color: isActive ? Colors.orangeAccent : Colors.white30,
              ),
              onTap: () => _playAffirmation(index),
            ),
          ),
        );
      },
    );
  }

  Future<void> _playAffirmation(int index) async {
    setState(() => _currentIndex = index);
    _animationController.forward(from: 0);
    if (!_isGuidedModeActive) return;
    await _audioPlayer.setAsset(_affirmations[index].audioPath);
    await _audioPlayer.play();
  }

  void _toggleGuidedMode(bool value) {
    setState(() => _isGuidedModeActive = value);
    if (!value) {
      _audioPlayer.stop();
      _advanceTimer?.cancel();
      return;
    }
    _playAffirmation(_currentIndex);
  }

  void _advanceToNext() {
    if (!_isGuidedModeActive) return;
    final nextIndex = (_currentIndex + 1) % _affirmations.length;
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _playAffirmation(nextIndex);
    });
  }
}
