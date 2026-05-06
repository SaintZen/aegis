import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ClinicalEntry {
  ClinicalEntry({
    required this.tool,
    required this.preValue,
    required this.postValue,
    required this.timestamp,
  });

  final String tool;
  final double preValue;
  final double postValue;
  final DateTime timestamp;

  static ClinicalEntry? fromJson(Map<String, dynamic> json) {
    final tool = json['tool'];
    final pre = json['pre_value'];
    final post = json['post_value'];
    final timestamp = json['timestamp'];
    if (tool is! String || pre == null || post == null || timestamp is! String) {
      return null;
    }
    return ClinicalEntry(
      tool: tool,
      preValue: (pre as num).toDouble(),
      postValue: (post as num).toDouble(),
      timestamp: DateTime.tryParse(timestamp) ?? DateTime.now(),
    );
  }
}

class ToolStats {
  ToolStats({
    required this.count,
    required this.avgPre,
    required this.avgPost,
    required this.avgDelta,
  });

  final int count;
  final double avgPre;
  final double avgPost;
  final double avgDelta;
}

class ClinicalLogService {
  static const _storageKey = 'clinical_entries';

  static Future<void> saveClinicalEntry({
    required String tool,
    required double preValue,
    required double postValue,
  }) async {
    final entry = <String, dynamic>{
      'tool': tool,
      'pre_value': preValue,
      'post_value': postValue,
      'delta': preValue - postValue,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_storageKey) ?? <String>[];
    entries.add(jsonEncode(entry));
    await prefs.setStringList(_storageKey, entries);
  }

  static Future<void> saveWeeklyRetrospective({
    required String weather,
    required int sleepScore,
    required int socialScore,
  }) async {
    final entry = <String, dynamic>{
      'type': 'WEEKLY_SUMMARY',
      'weather': weather,
      'sleep': sleepScore,
      'social': socialScore,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_storageKey) ?? <String>[];
    entries.add(jsonEncode(entry));
    await prefs.setStringList(_storageKey, entries);
  }

  static Future<List<ClinicalEntry>> loadClinicalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getStringList(_storageKey) ?? <String>[];
    return rawEntries
        .map((raw) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is Map<String, dynamic>) {
              return ClinicalEntry.fromJson(decoded);
            }
          } catch (_) {}
          return null;
        })
        .whereType<ClinicalEntry>()
        .toList();
  }

  static Future<List<ClinicalEntry>> getEntries() async {
    return loadClinicalEntries();
  }

  static Future<Map<String, dynamic>> getLatestWeeklySummary() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getStringList(_storageKey) ?? <String>[];
    Map<String, dynamic>? latest;
    DateTime? latestTimestamp;

    for (final raw in rawEntries) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic> &&
            decoded['type'] == 'WEEKLY_SUMMARY') {
          final timestamp = DateTime.tryParse(decoded['timestamp'] ?? '');
          if (timestamp == null) continue;
          if (latestTimestamp == null || timestamp.isAfter(latestTimestamp)) {
            latestTimestamp = timestamp;
            latest = decoded;
          }
        }
      } catch (_) {}
    }

    return latest ?? <String, dynamic>{};
  }

  static Map<String, ToolStats> aggregateEfficacy(
    List<ClinicalEntry> entries,
  ) {
    final Map<String, List<ClinicalEntry>> grouped = {};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.tool, () => []).add(entry);
    }

    return grouped.map((tool, list) {
      final count = list.length;
      final totalPre = list.fold<double>(0, (sum, e) => sum + e.preValue);
      final totalPost = list.fold<double>(0, (sum, e) => sum + e.postValue);
      final totalDelta =
          list.fold<double>(0, (sum, e) => sum + (e.preValue - e.postValue));
      return MapEntry(
        tool,
        ToolStats(
          count: count,
          avgPre: totalPre / count,
          avgPost: totalPost / count,
          avgDelta: totalDelta / count,
        ),
      );
    });
  }
}
