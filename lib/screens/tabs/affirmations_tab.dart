import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AffirmationsTab extends StatelessWidget {
  const AffirmationsTab({super.key});

  final List<Map<String, String>> affirmations = const [
    {'text': 'I am safe in this moment.', 'category': 'Peace'},
    {
      'text': 'This feeling is temporary. I have survived this before.',
      'category': 'Strength',
    },
    {
      'text': "I don't have to figure it all out right now.",
      'category': 'Peace',
    },
    {'text': 'My breath is my anchor. I am grounded.', 'category': 'Strength'},
    {'text': 'I am proud of myself for handling this.', 'category': 'Affirmation'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: affirmations.length,
      itemBuilder: (context, index) {
        final item = affirmations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: Icon(
              item['category'] == 'Strength' ? Icons.fitness_center : Icons.spa,
              color: Colors.green[600],
            ),
            title: Text(item['text']!, style: const TextStyle(fontSize: 16)),
            subtitle: Text(
              item['category']!,
              style: TextStyle(
                color: Colors.green[900],
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Clipboard.setData(ClipboardData(text: item['text']!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Anchor copied to clipboard.')),
              );
            },
          ),
        );
      },
    );
  }
}
