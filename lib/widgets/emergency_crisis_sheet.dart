import 'package:flutter/material.dart';
import 'package:anxiety_anchor/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// International crisis hotlines for the "Get Professional Help" flow.
/// Directs users away from the app toward human professionals in real crisis.
class EmergencyCrisisSheet {
  EmergencyCrisisSheet._();

  static const List<_CrisisLine> _lines = [
    _CrisisLine('United States', '988', '988 Suicide & Crisis Lifeline', 'tel:988'),
    _CrisisLine('United States', '741741', 'Crisis Text Line (text HOME)', 'sms:741741?body=HOME'),
    _CrisisLine('Canada', '988', '988 Suicide Crisis Helpline', 'tel:988'),
    _CrisisLine('UK', '116 123', 'Samaritans', 'tel:116123'),
    _CrisisLine('Australia', '13 11 14', 'Lifeline', 'tel:131114'),
  ];

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1116),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.emergency,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.support_resources_header,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.support_resources_intro,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.support_emergency_line,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ..._lines.map((line) => _buildCrisisTile(context, line)),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.local_hospital, color: Colors.redAccent),
                    title: const Text('Find Local Emergency Room'),
                    subtitle: const Text('Search nearby ERs'),
                    onTap: () {
                      Navigator.pop(context);
                      launchUrl(Uri.parse('https://www.google.com/maps/search/er+near+me'));
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildCrisisTile(BuildContext context, _CrisisLine line) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.phone_in_talk, color: Colors.redAccent),
        title: Text(
          line.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${line.country} · ${line.number}',
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
        onTap: () {
          Navigator.pop(context);
          launchUrl(Uri.parse(line.uri));
        },
      ),
    );
  }
}

class _CrisisLine {
  const _CrisisLine(this.country, this.number, this.title, this.uri);
  final String country;
  final String number;
  final String title;
  final String uri;
}
