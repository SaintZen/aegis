import 'package:flutter/material.dart';

import 'package:anxiety_anchor/data/dictionary_entries.dart';
import 'package:anxiety_anchor/l10n/app_localizations.dart';
import 'package:anxiety_anchor/services/telemetry.dart';

/// Searchable care-role dictionary backed by [dictionaryEntries].
class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  List<Map<String, String>> _items = List<Map<String, String>>.from(
    dictionaryEntries,
  );

  @override
  void initState() {
    super.initState();
    Telemetry.emit('dictionary_view', {'source': 'dictionary_screen'});
  }

  void _onSearch(String q) {
    setState(() {
      final needle = q.trim().toLowerCase();
      if (needle.isEmpty) {
        _items = List<Map<String, String>>.from(dictionaryEntries);
        return;
      }
      _items = dictionaryEntries.where((e) {
        final text =
            '${e['title']} ${e['short']} ${e['detail']}'.toLowerCase();
        return text.contains(needle);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          l10n.dictionaryTitle,
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            letterSpacing: 1.2,
            fontSize: 14,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: _onSearch,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'RobotoMono',
                fontSize: 14,
              ),
              cursorColor: Colors.white70,
              decoration: InputDecoration(
                hintText: l10n.dictionarySearchHint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.38),
                  fontFamily: 'RobotoMono',
                  fontSize: 13,
                ),
                filled: true,
                fillColor: const Color(0xFF121212),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white38),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      l10n.dictionaryNoResults,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontFamily: 'RobotoMono',
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: Colors.white12,
                      height: 1,
                    ),
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      final title = item['title'] ?? '';
                      final short = item['short'] ?? '';
                      return Semantics(
                        label: title,
                        hint: short,
                        button: true,
                        child: ListTile(
                          title: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'RobotoMono',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            short,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white60,
                              height: 1.35,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.white38,
                          ),
                          onTap: () => _showDetail(context, item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, String> item) {
    Telemetry.emit('dictionary_entry_view', {'id': item['id']});
    final l10n = AppLocalizations.of(context)!;
    final title = item['title'] ?? '';
    final detail = item['detail'] ?? '';
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1116),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              detail,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.5,
                fontSize: 14,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.dictionaryClose),
            ),
          ],
        );
      },
    );
  }
}
