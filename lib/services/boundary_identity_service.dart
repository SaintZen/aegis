import 'package:shared_preferences/shared_preferences.dart';

/// Stored display name for boundary / Not Today script injection ([Your Name]).
class BoundaryIdentityService {
  BoundaryIdentityService._();

  static const String _key = 'aegis_boundary_display_name';

  static Future<String> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_key) ?? '').trim();
  }

  static Future<void> setDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, name.trim());
  }
}
