import 'package:flutter/material.dart';

class KineticExercisesScreen extends StatelessWidget {
  const KineticExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Kinetic Exercises'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'If you feel faint, sit down and let go.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              _buildNavCard(
                context,
                title: 'Wall Pushes',
                subtitle: 'Guided movement with visual pacing.',
                onTap: () => Navigator.pushNamed(context, '/wall-pushes'),
              ),
              const SizedBox(height: 16),
              _buildNavCard(
                context,
                title: 'Voice-Guided Drills',
                subtitle: 'Hands-free audio drills with a form preview.',
                onTap: () => Navigator.pushNamed(context, '/kinetic-voice'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
