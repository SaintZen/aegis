import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:anxiety_anchor/models/vault_model.dart';
import 'package:anxiety_anchor/services/aegis_crypto.dart';

class VaultService {
  static const String _storageKey = 'aegis_vault_data';

  Future<void> saveEntry(VaultEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(entry.toJson());
    final stored = await AegisCrypto.instance.encryptString(payload);
    await prefs.setString(_storageKey, stored);
  }

  Future<VaultEntry?> loadEntry() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return null;
    try {
      // decryptString passes legacy plaintext through unchanged, so entries
      // written before encryption still load — and get re-encrypted on the
      // next saveEntry (transparent migration).
      final payload = await AegisCrypto.instance.decryptString(data);
      return VaultEntry.fromJson(jsonDecode(payload));
    } catch (_) {
      return null;
    }
  }

  Future<void> clearVault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
