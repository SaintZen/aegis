import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AffirmationAudioPlayer extends StatelessWidget {
  final String category;
  final bool playRandomOnPress;
  final AudioPlayer player = AudioPlayer();

  AffirmationAudioPlayer({
    super.key,
    required this.category,
    this.playRandomOnPress = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.play_circle_fill, size: 40, color: Colors.green),
      onPressed: () async {
        if (playRandomOnPress) {
          await playRandomAcceptance();
          return;
        }
        await player.play(AssetSource('audio/$category.mp3'));
      },
    );
  }

  Future<void> playRandomAcceptance() async {
    final int fileNumber = Random().nextInt(19) + 1;
    final String fileName = fileNumber.toString().padLeft(2, '0');
    try {
      await player.play(
        AssetSource('audio/vo_acceptance_$fileName.mp3'),
      );
    } catch (e) {
      debugPrint('Could not find vo_acceptance_$fileName.mp3');
    }
  }
}
