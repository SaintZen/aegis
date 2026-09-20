import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:anxiety_anchor/models/vault_model.dart';

class VaultService {
  static const String _storageKey = 'aegis_vault_data';
  static const String _archiveKey = 'aegis_vault_archive';

  Future<void> saveEntry(VaultEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = await loadEntry();
    if (previous != null &&
        previous.lockedAt != entry.lockedAt &&
        previous.isInReflectionWindow) {
      await _setArchiveDiscarded(previous.lockedAt);
    }
    await prefs.setString(_storageKey, jsonEncode(entry.toJson()));
    await _upsertArchive(VaultAuditRecord.fromEntry(entry));
  }

  Future<VaultEntry?> loadEntry() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return null;
    return VaultEntry.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  Future<void> clearVault() async {
    final current = await loadEntry();
    if (current != null && current.isInReflectionWindow) {
      await _setArchiveDiscarded(current.lockedAt);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Deposits that have left the 8h reflection window and were not discarded.
  Future<List<VaultAuditRecord>> loadAuditArchive({DateTime? now}) async {
    final all = await _loadArchiveRaw();
    return all.where((r) => r.appearsInAuditPdf(now)).toList(growable: false);
  }

  Future<List<VaultAuditRecord>> _loadArchiveRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_archiveKey) ?? const <String>[];
    final out = <VaultAuditRecord>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          out.add(VaultAuditRecord.fromJson(decoded));
        } else if (decoded is Map) {
          out.add(VaultAuditRecord.fromJson(decoded.cast<String, dynamic>()));
        }
      } catch (_) {}
    }
    return out;
  }

  Future<void> _upsertArchive(VaultAuditRecord record) async {
    final existing = await _loadArchiveRaw();
    final next = <VaultAuditRecord>[];
    var replaced = false;
    for (final row in existing) {
      if (row.lockedAt == record.lockedAt) {
        next.add(record);
        replaced = true;
      } else {
        next.add(row);
      }
    }
    if (!replaced) next.add(record);
    await _writeArchive(next);
  }

  Future<void> _setArchiveDiscarded(DateTime lockedAt) async {
    final existing = await _loadArchiveRaw();
    final next = existing
        .map(
          (row) =>
              row.lockedAt == lockedAt ? row.copyWith(discarded: true) : row,
        )
        .toList(growable: false);
    await _writeArchive(next);
  }

  Future<void> _writeArchive(List<VaultAuditRecord> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _archiveKey,
      rows.map((r) => jsonEncode(r.toJson())).toList(growable: false),
    );
  }
}
