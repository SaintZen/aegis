import 'package:flutter/material.dart';

import 'package:anxiety_anchor/models/tactical_briefing.dart';

class ResourceDetailScreen extends StatelessWidget {
  const ResourceDetailScreen({super.key, this.initialTitle});

  final String? initialTitle;

  List<TacticalBriefing> _orderedBriefings() {
    final entries = TacticalBriefing.entries;
    if (initialTitle == null) {
      return entries;
    }
    final index = entries.indexWhere((entry) => entry.title == initialTitle);
    if (index <= 0) {
      return entries;
    }
    final selected = entries[index];
    return [
      selected,
      ...entries.where((entry) => entry.title != selected.title),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Resource Detail'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView.builder(
          itemCount: _orderedBriefings().length,
          itemBuilder: (context, index) {
            final briefing = _orderedBriefings()[index];
            return _DetailSection(
              title: briefing.title,
              mechanism: briefing.mechanism,
              insight: briefing.tacticalNugget,
            );
          },
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.mechanism,
    required this.insight,
  });

  final String title;
  final String mechanism;
  final String insight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
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
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mechanism,
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              insight,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
