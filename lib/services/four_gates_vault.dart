import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:anxiety_anchor/models/four_gates_run.dart';

/// Persistence layer for Four Gates runs.
///
/// Stores at most [maxRuns] runs (most recent first) as a JSON string list
/// under [_storageKey]. No PII is emitted to telemetry from this file; the
/// evidence text lives only on-device in `SharedPreferences`.
class FourGatesVault {
  FourGatesVault({SharedPreferences? prefs}) : _prefs = prefs;

  static const String _storageKey = 'four_gates_runs';
  static const int maxRuns = 5;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Loads stored runs, newest first. Corrupt entries are skipped.
  Future<List<FourGatesRun>> load() async {
    final prefs = await _ensure();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final out = <FourGatesRun>[];
    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry) as Map<String, dynamic>;
        out.add(FourGatesRun.fromJson(decoded));
      } catch (_) {
        // Skip corrupt row; do not throw.
      }
    }
    return out;
  }

  /// Appends [run] as the newest entry and trims to [maxRuns].
  /// Returns the new list, newest first.
  Future<List<FourGatesRun>> append(FourGatesRun run) async {
    final existing = await load();
    final next = <FourGatesRun>[run, ...existing];
    if (next.length > maxRuns) {
      next.removeRange(maxRuns, next.length);
    }
    final prefs = await _ensure();
    await prefs.setStringList(
      _storageKey,
      next.map((r) => jsonEncode(r.toJson())).toList(),
    );
    return next;
  }

  Future<void> clear() async {
    final prefs = await _ensure();
    await prefs.remove(_storageKey);
  }
}
