import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:anxiety_anchor/widgets/advocacy_support_block.dart';
import 'package:anxiety_anchor/widgets/file_complaint_section.dart';

class AdvocacyScreen extends StatelessWidget {
  const AdvocacyScreen({super.key});

  static const String _paperTrailTemplate = '''DATE: [Current Date]
TO: [HR/Insurance Contact Name]
RE: Summary of Discussion regarding [Claim/Accommodation]

Per our conversation today at [Time], I am summarizing the key points discussed to ensure our records align:

It was stated that [Specific Statement Made by Rep].

My request for [X] is currently [Status: Pending/Denied].

The next required action is [Next Step] by [Date].

If any of the above does not match your understanding of our conversation, please provide a written correction by the end of the next business day.

Best, [User Name]
''';

  Future<void> _copyPaperTrailTemplate(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _paperTrailTemplate));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Shield'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shield tools. External routing and record-keeping only.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Quick-start: if it isn\'t in an email, it didn\'t happen. '
                'Write it down right away.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Rules can change by state. Always check local deadlines.',
                style: TextStyle(color: Colors.white54, height: 1.5),
              ),
              const SizedBox(height: 24),
              _AdvocacyModuleCard(
                title: 'HR Works for the Company',
                subtitle: 'Be clear and keep it in writing.',
                body:
                    'Be polite and professional. Put requests in writing so there is a '
                    'record.',
                action: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/fiduciary-truth',
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Read the Details'),
                ),
              ),
              const SizedBox(height: 16),
              _AdvocacyModuleCard(
                title: 'Write It Down',
                subtitle: 'Use a simple meeting recap.',
                body:
                    'After any talk, send a short recap so your record is locked.',
                action: ElevatedButton.icon(
                  onPressed: () => _copyPaperTrailTemplate(context),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Recap'),
                ),
              ),
              const SizedBox(height: 16),
              _AdvocacySwipeCard(
                title: 'Calm, Clear Status',
                cards: const [
                  _ProtocolCard(
                    title: 'The Narrative',
                    body:
                        'I am in Active Calibration. I am using tools to stay steady and '
                        'focused.',
                  ),
                  _ProtocolCard(
                    title: 'The Barrier',
                    body:
                        'My goal is clear thinking and good work. I use tools that keep me '
                        'on track.',
                  ),
                  _ProtocolCard(
                    title: 'The Final Word',
                    body:
                        'I do not need extra handling. I need quick access to my tools.',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const AdvocacySupportBlock(),
              const SizedBox(height: 16),
              const FileComplaintSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvocacyModuleCard extends StatelessWidget {
  const _AdvocacyModuleCard({
    required this.title,
    required this.subtitle,
    required this.body,
    this.action,
  });

  final String title;
  final String subtitle;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white60, height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            action!,
          ],
        ],
      ),
    );
  }
}

class _AdvocacySwipeCard extends StatefulWidget {
  const _AdvocacySwipeCard({
    required this.title,
    required this.cards,
  });

  final String title;
  final List<_ProtocolCard> cards;

  @override
  State<_AdvocacySwipeCard> createState() => _AdvocacySwipeCardState();
}

class _AdvocacySwipeCardState extends State<_AdvocacySwipeCard> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.cards.length,
              itemBuilder: (context, index) {
                final card = widget.cards[index];
                return _ProtocolCardView(card: card);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtocolCard {
  const _ProtocolCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

class _ProtocolCardView extends StatelessWidget {
  const _ProtocolCardView({required this.card});

  final _ProtocolCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            card.body,
            style: const TextStyle(color: Colors.white, height: 1.45),
          ),
        ],
      ),
    );
  }
}
