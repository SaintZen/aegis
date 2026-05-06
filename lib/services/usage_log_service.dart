import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Usage logging for Lab tools. All log methods are async and perform I/O.
/// Call with [unawaited] to avoid blocking the UI thread or haptic feedback.
class UsageLogService {
  static const _storageKey = 'anchor_usage_logs';

  static Future<void> logAnchorUsage({
    required String flavor,
    required int durationSeconds,
  }) async {
    final entry = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'flavor': flavor,
      'duration_seconds': durationSeconds,
    };

    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList(_storageKey) ?? <String>[];
    logs.add(jsonEncode(entry));
    await prefs.setStringList(_storageKey, logs);
  }

  /// Log one item processed via The Void (for Cognitive Load Management count).
  static Future<void> logVoidRelease() async {
    await logAnchorUsage(flavor: 'The Void', durationSeconds: 0);
  }

  static Future<List<UsageLogEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList(_storageKey) ?? <String>[];
    final entries = <UsageLogEntry>[];
    for (final raw in logs) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final ts = decoded['timestamp'] as String?;
        final flavor = decoded['flavor'] as String?;
        final dur = decoded['duration_seconds'];
        if (ts != null && flavor != null && dur != null) {
          entries.add(UsageLogEntry(
            timestamp: DateTime.tryParse(ts) ?? DateTime.now(),
            flavor: flavor,
            durationSeconds: (dur is int) ? dur : (dur as num).toInt(),
          ));
        }
      } catch (_) {}
    }
    return entries;
  }
}

class UsageLogEntry {
  const UsageLogEntry({
    required this.timestamp,
    required this.flavor,
    required this.durationSeconds,
  });

  final DateTime timestamp;
  final String flavor;
  final int durationSeconds;
}
