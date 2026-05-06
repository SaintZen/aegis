import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:anxiety_anchor/models/pending_retest.dart';

/// Persistence layer for [PendingRetest] contracts.
///
/// ## Doctrine
///
/// Stores the FAILURE-only re-test contracts emitted by FOUR GATES. One
/// record per FAILURE run, lifetime: created at `_finalize()`, removed
/// when the operator ratifies or overturns the verdict (Phase 1.4-C).
/// Until then, the record is durable evidence that the imagination has
/// not yet been allowed to rewrite the verdict.
///
/// ## Retention policy
///
/// * No automatic expiry in Phase 1.4-A. The doctrine treats an
///   un-ratified FAILURE as itself a data point — the operator never
///   came back. We do not silently delete that.
/// * No upper bound on the count in Phase 1.4-A. Practically, this list
///   is small: the [FourGatesVault] caps history at 5 runs and only
///   FAILURE runs produce contracts. If retention becomes a concern,
///   we cap here in Phase 1.4-B/C — additive, no migration needed.
/// * Corrupt rows are skipped on load, never thrown.
///
/// ## No PII to telemetry
///
/// Same constraint as [FourGatesVault]: evidence text lives only on
/// device. This file emits no telemetry; callers that do are responsible
/// for redacting.
class PendingRetestStore {
  PendingRetestStore({SharedPreferences? prefs}) : _prefs = prefs;

  /// SharedPreferences key namespacing the pending re-test list. Distinct
  /// from `four_gates_runs` so the two stores cannot stomp each other.
  static const String storageKey = 'four_gates_pending_retests';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Loads all stored pending re-tests, newest-due first. Corrupt rows
  /// are silently skipped so a single bad entry cannot brick the surface.
  Future<List<PendingRetest>> load() async {
    final prefs = await _ensure();
    final raw = prefs.getStringList(storageKey) ?? const <String>[];
    final out = <PendingRetest>[];
    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry) as Map<String, dynamic>;
        out.add(PendingRetest.fromJson(decoded));
      } catch (_) {
        // Skip corrupt row.
      }
    }
    out.sort((a, b) => b.dueAt.compareTo(a.dueAt));
    return out;
  }

  /// Appends [retest] as a new pending contract. If a record with the
  /// same `id` already exists, it is replaced rather than duplicated.
  /// Returns the new full list, newest-due first.
  Future<List<PendingRetest>> add(PendingRetest retest) async {
    final existing = await load();
    final without = existing.where((r) => r.id != retest.id);
    final next = <PendingRetest>[retest, ...without];
    return _persist(next);
  }

  /// Removes the contract with [id] if it exists. Returns the new list.
  /// No-op if [id] is unknown.
  Future<List<PendingRetest>> removeById(String id) async {
    final existing = await load();
    final next = existing.where((r) => r.id != id).toList();
    if (next.length == existing.length) return existing;
    return _persist(next);
  }

  /// Replaces the record matching [retest.id] with [retest], preserving
  /// list order semantics ("ratify in place"). If no record with that
  /// id exists, [retest] is appended (same shape as `add`).
  ///
  /// Phase 1.4-C uses this when the operator finishes a re-test —
  /// the contract is mutated from `pending` to `ratifiedConfirmed` /
  /// `ratifiedOverturned` rather than removed, so the audit trail
  /// stays intact across the operator's lifetime.
  Future<List<PendingRetest>> update(PendingRetest retest) => add(retest);

  /// Returns only the records whose [PendingRetest.dueAt] is at or
  /// before `now` AND whose status is still `pending`. Pure read.
  /// Ratified records, even if `dueAt` is in the past, are NOT due —
  /// they have already been resolved.
  Future<List<PendingRetest>> loadDue({required DateTime now}) async {
    final all = await load();
    return all
        .where((r) => r.isDue(now: now) && !r.isRatified)
        .toList(growable: false);
  }

  /// Returns only the records whose status is `ratifiedConfirmed` or
  /// `ratifiedOverturned`, sorted newest-ratified-first. Powers the
  /// PDF "RATIFICATION RECORDS" section (Phase 1.4-C).
  Future<List<PendingRetest>> loadRatified() async {
    final all = await load();
    final ratified = all.where((r) => r.isRatified).toList()
      ..sort((a, b) {
        final aAt = a.ratifiedAt ?? a.dueAt;
        final bAt = b.ratifiedAt ?? b.dueAt;
        return bAt.compareTo(aAt);
      });
    return ratified;
  }

  Future<void> clear() async {
    final prefs = await _ensure();
    await prefs.remove(storageKey);
  }

  Future<List<PendingRetest>> _persist(List<PendingRetest> list) async {
    list.sort((a, b) => b.dueAt.compareTo(a.dueAt));
    final prefs = await _ensure();
    await prefs.setStringList(
      storageKey,
      list.map((r) => jsonEncode(r.toJson())).toList(growable: false),
    );
    return list;
  }
}
