import 'package:flutter/material.dart';

class WellnessHub extends StatelessWidget {
  const WellnessHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('The Hold'),
        backgroundColor: const Color(0xFF003366),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWellnessAction(
            title: 'The Hold',
            subtitle: 'Simple breathing presets',
            icon: Icons.air,
            color: const Color(0xFF003366),
            onTap: () => _navigateToBreathing(context),
          ),
          _buildWellnessAction(
            title: 'PMR & Body',
            subtitle: 'Breathing and physical relief techniques',
            icon: Icons.fitness_center,
            color: const Color(0xFF1B5E20),
            onTap: () => _navigateToPmr(context),
          ),
          _buildWellnessAction(
            title: 'Audio Library',
            subtitle: 'Guided affirmations and calm tracks',
            icon: Icons.library_music,
            color: const Color(0xFF4B6B88),
            onTap: () => _navigateToAudioLibrary(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWellnessAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white24,
        ),
        onTap: onTap,
      ),
    );
  }

  void _navigateToBreathing(BuildContext context) {
    Navigator.pushNamed(context, '/rescue-breathing');
  }

  void _navigateToPmr(BuildContext context) {
    Navigator.pushNamed(context, '/pmr-body');
  }

  void _navigateToAudioLibrary(BuildContext context) {
    Navigator.pushNamed(context, '/audio-library');
  }
}
