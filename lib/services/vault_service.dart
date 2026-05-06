import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:anxiety_anchor/models/vault_model.dart';

class VaultService {
  static const String _storageKey = 'aegis_vault_data';

  Future<void> saveEntry(VaultEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(entry.toJson()));
  }

  Future<VaultEntry?> loadEntry() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return null;
    return VaultEntry.fromJson(jsonDecode(data));
  }

  Future<void> clearVault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
