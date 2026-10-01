import 'package:shared_preferences/shared_preferences.dart';

import '../models/allergen_preference.dart';

class PreferenceService {
  // ignore: prefer_initializing_formals, intentional nullable injection for tests
  PreferenceService({SharedPreferences? prefs}) : _prefs = prefs;

  static const String userNameKey = 'preference_user_name';
  static const String allergensKey = 'preference_allergens';

  final SharedPreferences? _prefs;

  Future<SharedPreferences> _resolvePrefs() async {
    if (_prefs != null) return _prefs;
    return SharedPreferences.getInstance();
  }

  Future<AllergenPreference> loadPreferences() async {
    try {
      final prefs = await _resolvePrefs();
      final userName = prefs.getString(userNameKey) ?? '';
      final allergens = prefs.getStringList(allergensKey) ?? <String>[];
      return AllergenPreference(
        userName: userName,
        selectedAllergens: allergens.toSet(),
      );
    } catch (_) {
      throw const PreferenceLoadFailure();
    }
  }

  Future<void> savePreferences(AllergenPreference preference) async {
    try {
      final prefs = await _resolvePrefs();
      await prefs.setString(userNameKey, preference.userName);
      await prefs.setStringList(
        allergensKey,
        preference.selectedAllergens.toList(),
      );
    } catch (_) {
      throw const PreferenceSaveFailure();
    }
  }
}

class PreferenceLoadFailure implements Exception {
  const PreferenceLoadFailure();
}

class PreferenceSaveFailure implements Exception {
  const PreferenceSaveFailure();
}
