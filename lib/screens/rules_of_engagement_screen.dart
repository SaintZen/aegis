import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class RulesOfEngagementScreen extends StatelessWidget {
  const RulesOfEngagementScreen({super.key});

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

  static const String _ebsaHelpUrl =
      'https://www.dol.gov/agencies/ebsa/about-ebsa/our-activities/resource-center/assistance';
  static const String _stateInsuranceUrl =
      'https://content.naic.org/state-insurance-departments';

  Future<void> _copyTemplate(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _paperTrailTemplate));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template copied to clipboard.')),
    );
  }

  Future<void> _launchExternal(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    if (!context.mounted) return;
    if (!canLaunch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the link.')),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('The Rules of Engagement'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _RulesCard(
              title: 'HR is a Fiduciary',
              subtitle: 'They protect the company, not you.',
              body:
                  'HR exists to mitigate legal risk for the company. Their incentives '
                  'are not aligned with your health or career stability. Treat every '
                  'HR interaction as formal, written, and documented.',
            ),
            _RulesCard(
              title: 'The Paper Trail',
              subtitle: 'Summarize every meeting in writing.',
              body:
                  'Never have a “quick chat.” Follow every meeting with a written '
                  'summary that confirms your request, the next steps, and any deadlines.',
              action: ElevatedButton.icon(
                onPressed: () => _copyTemplate(context),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Template'),
              ),
            ),
            _RulesCard(
              title: 'ERISA/DOI Rights',
              subtitle: 'File official complaints when claims are denied.',
              body:
                  'Use federal and state oversight channels when your claim is denied. '
                  'These portals provide guidance and enforcement pathways.',
              action: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _launchExternal(context, _ebsaHelpUrl),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('EBSA Federal Help Portal'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _launchExternal(context, _stateInsuranceUrl),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('State Insurance Commissioner'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({
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
      margin: const EdgeInsets.only(bottom: 16),
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
