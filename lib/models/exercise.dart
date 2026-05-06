import 'package:flutter/material.dart';

class Exercise {
  final String title;
  final String description;
  final IconData icon;
  final String instructions;
  final int durationSeconds; // Duration in seconds for the exercise
  final String howItWorks; // How the exercise works
  final String whyInTab; // Why it's in the tab

  const Exercise({
    required this.title,
    required this.description,
    required this.icon,
    required this.instructions,
    required this.durationSeconds,
    required this.howItWorks,
    required this.whyInTab,
  });
}

// List of anxiety exercises
class ExerciseData {
  static final List<Exercise> exercises = [
    Exercise(
      title: '5-4-3-2-1 Senses',
      description: 'Interactive prompts to name things you see, hear, touch, etc.',
      icon: Icons.visibility,
      instructions: 'Follow the prompts to name things using your senses.',
      durationSeconds: 0, // Interactive, no timer
      howItWorks: 'Interactive prompts to name things you see, hear, touch, etc.',
      whyInTab: 'The "Gold Standard" for stopping a panic attack.',
    ),
    Exercise(
      title: 'The "Shake Out"',
      description: 'A 30-second timer with a "vibrate" haptic to encourage physical movement.',
      icon: Icons.vibration,
      instructions: 'Stand up and shake your entire body. The phone will vibrate to guide you.',
      durationSeconds: 30,
      howItWorks: 'A 30-second timer with a "vibrate" haptic to encourage physical movement.',
      whyInTab: 'Releases pent-up "fight or flight" adrenaline.',
    ),
    Exercise(
      title: 'Wall Pushes',
      description: 'A guided visual showing how to "push" the wall to feel your own strength.',
      icon: Icons.touch_app,
      instructions: 'Push against the wall as hard as you can. Feel your strength and power. Hold for 10 seconds, then release. Repeat 3 times.',
      durationSeconds: 60, // 60 seconds total
      howItWorks: 'A guided visual showing how to "push" the wall to feel your own strength.',
      whyInTab: 'Provides immediate physical grounding.',
    ),
    Exercise(
      title: 'Box Breathing',
      description: 'A visual breathing guide with a 4-4-4-4 pattern to quickly calm your nervous system.',
      icon: Icons.square,
      instructions: 'Follow the visual guide: breathe in for 4, hold for 4, breathe out for 4, hold for 4. Repeat.',
      durationSeconds: 120, // 2 minutes of guided breathing
      howItWorks: 'A visual breathing guide with a 4-4-4-4 pattern to quickly calm your nervous system.',
      whyInTab: 'Activates the parasympathetic nervous system for immediate calm.',
    ),
  ];
}

