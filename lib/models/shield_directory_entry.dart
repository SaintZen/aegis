/// Typed record for one row in the Shield directory (external routing index).
///
/// Ordering, labels and category ids are defined alongside the data in
/// `lib/data/advocacy_support_links.dart`.
///
/// Legal gate: entries marked [placeholder] are excluded from the release-visible
/// list via [shieldDirectoryLiveEntries]. Flip [placeholder] to `false` only after
/// the URL has been vetted and signed off.
class ShieldDirectoryEntry {
  const ShieldDirectoryEntry({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.url,
    required this.verifiedAt,
    this.phone,
    this.sms,
    this.jurisdiction = 'national',
    this.placeholder = false,
  });

  final String id;
  final String category;
  final String title;
  final String description;
  final String url;
  final DateTime verifiedAt;

  /// E.164-ish phone digits (no `tel:` prefix). Optional.
  final String? phone;

  /// Short-code + keyword instruction (e.g. "Text HOME to 741741"). Optional.
  final String? sms;

  /// `national`, `state:XX`, or `local`. Default `national`.
  final String jurisdiction;

  /// Draft row. Hidden from [shieldDirectoryLiveEntries] until vetted.
  final bool placeholder;

  /// True if the URL passes the minimum shape checks used by the release gate.
  bool get hasValidUrl {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (!(uri.scheme == 'https' || uri.scheme == 'http')) return false;
    if (uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    const forbidden = {'example.org', 'example.com', 'example.edu', 'example.net'};
    if (forbidden.contains(host)) return false;
    return true;
  }

  /// `tel:` URI built from [phone] digits (non-digit chars stripped), or null.
  String? get telUri {
    final p = phone;
    if (p == null) return null;
    final digits = p.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return null;
    return 'tel:$digits';
  }
}
