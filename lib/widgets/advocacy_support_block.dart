import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:anxiety_anchor/data/advocacy_support_links.dart';
import 'package:anxiety_anchor/l10n/app_localizations.dart';
import 'package:anxiety_anchor/models/shield_directory_entry.dart';
import 'package:anxiety_anchor/services/telemetry.dart';
import 'package:anxiety_anchor/utils/launch_helper.dart';

/// Shield directory: external routing index (Aegis voice).
///
/// Shows live (non-placeholder) entries from [shieldDirectoryLiveEntries] with:
///   - category filter chips (horizontally scrollable)
///   - free-text search (title + description)
///   - per-row open / call / text affordances
///   - verified month/year line per row
///
/// [launchCallback] is injected by tests; in production it defaults to
/// [launchUrlHelper].
class AdvocacySupportBlock extends StatefulWidget {
  const AdvocacySupportBlock({
    super.key,
    this.launchCallback,
  });

  final LaunchCallback? launchCallback;

  @override
  State<AdvocacySupportBlock> createState() => _AdvocacySupportBlockState();
}

class _AdvocacySupportBlockState extends State<AdvocacySupportBlock> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _activeCategory;

  @override
  void initState() {
    super.initState();
    Telemetry.emit('advocacy_support_view', {'source': 'advocacy_screen'});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final all = shieldDirectoryLiveEntries;
    final filtered = _applyFilters(all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.support_resources_header,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.support_resources_intro,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.support_emergency_line,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.redAccent,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        _SearchField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        const SizedBox(height: 10),
        _CategoryChips(
          activeCategory: _activeCategory,
          onSelect: (cat) => setState(() => _activeCategory = cat),
        ),
        const SizedBox(height: 6),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No matching entries.',
              style: TextStyle(
                color: Colors.white54,
                fontFamily: 'RobotoMono',
                fontSize: 12,
              ),
            ),
          )
        else
          ..._groupedByCategory(filtered).entries.expand((group) {
            return [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 2),
                child: Text(
                  advocacySupportCategoryLabels[group.key] ?? group.key,
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade200,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              ...group.value.map((e) => _DirectoryTile(
                    entry: e,
                    onOpen: () => _openUrl(e),
                    onCall: e.telUri != null ? () => _callEntry(e) : null,
                    onCopy: () => _copyUrl(e),
                  )),
            ];
          }),
      ],
    );
  }

  Iterable<ShieldDirectoryEntry> _applyFilters(
    Iterable<ShieldDirectoryEntry> entries,
  ) {
    final q = _query.toLowerCase();
    return entries.where((e) {
      if (_activeCategory != null && e.category != _activeCategory) {
        return false;
      }
      if (q.isEmpty) return true;
      return e.title.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q);
    });
  }

  Map<String, List<ShieldDirectoryEntry>> _groupedByCategory(
    Iterable<ShieldDirectoryEntry> entries,
  ) {
    final out = <String, List<ShieldDirectoryEntry>>{};
    for (final cat in advocacySupportCategoryOrder) {
      final rows = entries.where((e) => e.category == cat).toList();
      if (rows.isNotEmpty) out[cat] = rows;
    }
    return out;
  }

  Future<void> _openUrl(ShieldDirectoryEntry entry) async {
    Telemetry.emit('advocacy_support_link_tap', {
      'category': entry.category,
      'link_id': entry.id,
      'action': 'open',
    });
    final callback = widget.launchCallback ?? launchUrlHelper;
    await callback(context, entry.url);
  }

  Future<void> _callEntry(ShieldDirectoryEntry entry) async {
    final tel = entry.telUri;
    if (tel == null) return;
    Telemetry.emit('advocacy_support_link_tap', {
      'category': entry.category,
      'link_id': entry.id,
      'action': 'call',
    });
    final callback = widget.launchCallback ?? launchUrlHelper;
    await callback(context, tel);
  }

  Future<void> _copyUrl(ShieldDirectoryEntry entry) async {
    await Clipboard.setData(ClipboardData(text: entry.url));
    Telemetry.emit('advocacy_support_link_tap', {
      'category': entry.category,
      'link_id': entry.id,
      'action': 'copy',
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied.')),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'RobotoMono',
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: 'Search directory',
        hintStyle: const TextStyle(
          color: Colors.white38,
          fontFamily: 'RobotoMono',
          fontSize: 13,
        ),
        prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.amber.shade200),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.activeCategory,
    required this.onSelect,
  });

  final String? activeCategory;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _chip(label: 'All', selected: activeCategory == null, onTap: () => onSelect(null)),
      for (final id in advocacySupportCategoryOrder)
        _chip(
          label: advocacySupportCategoryLabels[id] ?? id,
          selected: activeCategory == id,
          onTap: () => onSelect(id),
        ),
    ];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => chips[i],
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: chips.length,
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.amber.shade200.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
            color: selected ? Colors.amber.shade200 : Colors.white24,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.amber.shade200 : Colors.white70,
            fontFamily: 'RobotoMono',
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _DirectoryTile extends StatelessWidget {
  const _DirectoryTile({
    required this.entry,
    required this.onOpen,
    required this.onCall,
    required this.onCopy,
  });

  final ShieldDirectoryEntry entry;
  final VoidCallback onOpen;
  final VoidCallback? onCall;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final verified = _verifiedLabel(entry.verifiedAt);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      title: Text(
        entry.title,
        style: const TextStyle(
          fontFamily: 'RobotoMono',
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            entry.description,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (entry.sms != null) ...[
            const SizedBox(height: 2),
            Text(
              entry.sms!,
              style: const TextStyle(
                color: Colors.white54,
                fontFamily: 'RobotoMono',
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              Text(
                'VERIFIED $verified',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontFamily: 'RobotoMono',
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
              if (onCall != null)
                _actionButton(
                  icon: Icons.call,
                  label: 'CALL',
                  onTap: onCall!,
                ),
              _actionButton(
                icon: Icons.copy,
                label: 'COPY',
                onTap: onCopy,
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(
        Icons.open_in_new,
        color: Colors.white38,
        size: 20,
      ),
      onTap: onOpen,
      onLongPress: onCopy,
    );
  }

  String _verifiedLabel(DateTime d) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 13),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontFamily: 'RobotoMono',
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
