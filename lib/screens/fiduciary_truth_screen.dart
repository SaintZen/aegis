import 'package:flutter/material.dart';

class FiduciaryTruthScreen extends StatelessWidget {
  const FiduciaryTruthScreen({super.key});

  TextSpan _buildMarkdownSpan(String text, TextStyle baseStyle) {
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      final style = i.isOdd ? boldStyle : baseStyle;
      spans.add(TextSpan(text: parts[i], style: style));
    }
    return TextSpan(children: spans, style: baseStyle);
  }

  Widget _markdownText(String text, {double height = 1.5}) {
    const baseStyle = TextStyle(color: Colors.white70);
    return Text.rich(
      _buildMarkdownSpan(text, baseStyle.copyWith(height: height)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('The Fiduciary Truth'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              'THE FIDUCIARY TRUTH',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            _markdownText(
              'HR is a Corporate Risk Asset. You are a Sovereign Agent.',
              height: 1.4,
            ),
            const SizedBox(height: 20),
            const Text(
              'The Conflict of Interest',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _markdownText(
              'Human Resources (HR) and Insurance Carriers are corporate fiduciaries. '
              'Their legal and financial loyalty is to the company\'s bottom line and '
              'risk mitigation, not your personal outcome. When your health costs or '
              'leave requests threaten that bottom line, their primary role is to '
              'protect the organization. That is the architecture you are negotiating.',
            ),
            const SizedBox(height: 18),
            const Text(
              'The Paper Trail',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _markdownText(
              'The ADA "Interactive Process" is often framed as collaborative, but in '
              'practice it is a legal compliance exercise. Every casual check-in becomes '
              'a data point in a risk assessment. Without a paper trail, you are '
              'invisible. With a paper trail, you create an administrative record that '
              'must be respected.',
            ),
            const SizedBox(height: 18),
            const Text(
              'The Sovereignty Rules',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _markdownText(
              'Trust the process, not the person: your HR rep may be kind, but their '
              'job is to mitigate risk. Silence is a leak, so never leave a meeting '
              'without a written summary—if it isn\'t in an email, it didn\'t happen. '
              'Use the paper trail to transform from a "risk" into a sovereign '
              'liability. Anchor your requests in protocol language like "medically '
              'necessary" to trigger mandatory review timelines.',
              height: 1.6,
            ),
          ],
        ),
      ),
    );
  }
}
