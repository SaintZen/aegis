import 'package:flutter/material.dart';

import 'package:anxiety_anchor/l10n/app_localizations.dart';

import 'package:anxiety_anchor/data/dictionary_entries.dart';
import 'package:anxiety_anchor/data/resource_briefings_data.dart';
import 'package:anxiety_anchor/models/resource_article.dart';
import 'package:anxiety_anchor/models/resource_briefing.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          'AEGIS DEFINITIONS',
          style: TextStyle(
            fontFamily: 'RobotoMono',
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.dictionarySearchHint,
            onPressed: () => Navigator.pushNamed(context, '/dictionary'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionHeader(label: 'Critical Intel'),
          const SizedBox(height: 8),
          ...resourceBriefings
              .where((b) => b.id == 'foundation' || b.id == 'tactical_matrix')
              .map((b) => _ResourceCard(
                    briefing: b,
                    onTap: () => _showBriefing(context, b),
                  )),
          const SizedBox(height: 20),
          const _SectionHeader(label: 'Care & support roles'),
          const SizedBox(height: 8),
          ...dictionaryEntries.map(
            (e) => _DictionaryEntryCard(
              entry: e,
              onTap: () => _showDictionaryEntry(context, e),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionHeader(label: 'More Resources'),
          const SizedBox(height: 8),
          ...resourceBriefings
              .where((b) => b.id != 'foundation' && b.id != 'tactical_matrix')
              .map((b) => _ResourceCard(
                    briefing: b,
                    onTap: () => _showBriefing(context, b),
                  )),
        ],
      ),
    );
  }

  void _showDictionaryEntry(BuildContext context, Map<String, String> e) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1116),
          title: Text(
            e['title'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e['short'] ?? '',
                  style: const TextStyle(
                    color: Colors.white60,
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  e['detail'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showBriefing(BuildContext context, ResourceBriefing briefing) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1116),
          title: Text(briefing.dialogTitle ?? briefing.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: briefing.articles
                  .map((a) => _BriefingSection(article: a))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.amber.shade200,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _DictionaryEntryCard extends StatelessWidget {
  const _DictionaryEntryCard({
    required this.entry,
    required this.onTap,
  });

  final Map<String, String> entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.badge_outlined, color: Colors.amber),
        title: Text(
          entry['title'] ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          entry['short'] ?? '',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.briefing,
    required this.onTap,
  });

  final ResourceBriefing briefing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(briefing.icon, color: Colors.amber),
        title: Text(
          briefing.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          briefing.subtitle,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}

class _BriefingSection extends StatelessWidget {
  const _BriefingSection({required this.article});

  final ResourceArticle article;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (article.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              article.subtitle!,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            article.body,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          if (article.quickActions != null && article.quickActions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Quick Action',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            _QuickActionTable(rows: article.quickActions!),
          ],
        ],
      ),
    );
  }
}

class _QuickActionTable extends StatelessWidget {
  const _QuickActionTable({required this.rows});

  final List<QuickActionRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'State',
                    style: TextStyle(
                      color: Colors.amber.shade200,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Tool',
                    style: TextStyle(
                      color: Colors.amber.shade200,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: isLast ? null : Border(bottom: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      e.value.state,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      e.value.tool,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
