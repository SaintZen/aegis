import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:anxiety_anchor/models/journal_entry.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key, this.entries = const []});

  final List<JournalEntry> entries;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String _selectedMood = 'Neutral';

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMoodSelector(),
          const SizedBox(height: 20),
          if (entries.isEmpty)
            _buildEmptyState()
          else
            ...entries.map(_buildJournalEntryCard),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Text(
          'No entries yet. Add a journal note to track your progress.',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
          textAlign: TextAlign.center,
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: moods.entries.map((entry) {
        final isSelected = _selectedMood == entry.key;
        final color = isSelected ? Colors.amber : Colors.white24;
        return Column(
          children: [
            IconButton(
              icon: Icon(entry.value, color: color),
              onPressed: () => setState(() => _selectedMood = entry.key),
            ),
            Text(entry.key, style: TextStyle(color: color, fontSize: 10)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildJournalEntryCard(JournalEntry entry) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(entry.timestamp),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Level ${entry.distressLevel}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              entry.note,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (entry.symptoms.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 5,
                runSpacing: 6,
                children: entry.symptoms
                    .map(
                      (symptom) => Chip(
                        label: Text(
                          symptom,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }

}
