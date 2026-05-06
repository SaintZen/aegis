import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Internal log for cognitive shifts during Vault Reflection and similar moments.
/// Never exported to PDF—privacy guard.
class CognitiveShiftLogService {
  static const _storageKey = 'aegis_cognitive_shift_log';

  static Future<void> logShift({
    required String context,
    required String response,
    bool isAha = false,
  }) async {
    final entry = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'context': context,
      'response': response,
      'isAha': isAha,
    };
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList(_storageKey) ?? <String>[];
    logs.add(jsonEncode(entry));
    await prefs.setStringList(_storageKey, logs);
  }
}
