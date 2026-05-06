import 'package:flutter/material.dart';

class PmrBodyScanTab extends StatelessWidget {
  const PmrBodyScanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Dizzy? Just let go and breathe.',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
          _buildSectionHeader('Breathing Exercises'),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildWellnessCard(
                '4-7-8 Breathing',
                'The Gold Standard for Panic',
                '4s In • 7s Hold • 8s Out',
                Icons.air,
                const Color(0xFF003366),
                onTap: () => _navigateToBreathing(context, '478'),
              ),
              _buildWellnessCard(
                'Cooling Breath',
                'Lowers body temperature & heart rate',
                '5s In • 5s Out',
                Icons.ac_unit,
                const Color(0xFF004080),
                onTap: () => _navigateToBreathing(context, 'cooling'),
              ),
              _buildWellnessCard(
                'Anchor Breath',
                'Heavy grounding for high dissociation',
                'Deep & Focused',
                Icons.anchor,
                const Color(0xFF002244),
                onTap: () => _navigateToBreathing(context, 'anchor'),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  'Dizzy? Stop and breathe normal.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ]),
          ),
          _buildSectionHeader('Physical Relief'),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildWellnessCard(
                'Progressive Muscle Relaxation (PMR)',
                'Release stored tension systematically',
                'Voice Guided',
                Icons.fitness_center,
                Colors.green[900]!.withOpacity(0.3),
                onTap: () => _navigateToAudio(
                  context,
                  'pmr_voice',
                  'PMR Voice Guide',
                ),
              ),
              _buildWellnessCard(
                'Full Body Scan',
                'Mindful awareness of physical state',
                'Voice Guided',
                Icons.self_improvement,
                Colors.teal[900]!.withOpacity(0.3),
                onTap: () => _navigateToAudio(
                  context,
                  'body_scan_voice',
                  'Body Scan Voice Guide',
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildWellnessCard(
    String title,
    String sub,
    String spec,
    IconData icon,
    Color accent, {
    VoidCallback? onTap,
  }
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, color: Colors.white, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sub, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
              spec,
              style: TextStyle(
                color: accent.withOpacity(0.8),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
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

  void _navigateToBreathing(BuildContext context, String preset) {
    Navigator.pushNamed(
      context,
      '/rescue-breathing',
      arguments: {'preset': preset},
    );
  }

  void _navigateToAudio(BuildContext context, String track, String title) {
    Navigator.pushNamed(
      context,
      '/audio-player',
      arguments: {
        'track': track,
        'title': title,
      },
    );
  }
}
