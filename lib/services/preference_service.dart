import 'package:shared_preferences/shared_preferences.dart';

import '../models/allergen_preference.dart';
import '../models/failures.dart';

class PreferenceService {
  static const String nameKey = 'preference_user_name';
  static const String allergensKey = 'preference_allergens';

  Future<AllergenPreference> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return AllergenPreference(
        userName: prefs.getString(nameKey) ?? '',
        selectedAllergens: (prefs.getStringList(allergensKey) ?? const <String>[]).toSet(),
      );
    } catch (_) {
      throw const PreferenceLoadFailure();
    }
  }

  Future<void> save(AllergenPreference preference) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nameSaved = await prefs.setString(nameKey, preference.userName);
      final allergensSaved = await prefs.setStringList(allergensKey, preference.selectedAllergens.toList()..sort());
      if (!nameSaved || !allergensSaved) throw const PreferenceSaveFailure();
    } on PreferenceSaveFailure {
      rethrow;
    } catch (_) {
      throw const PreferenceSaveFailure();
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(nameKey);
      await prefs.remove(allergensKey);
    } catch (_) {
      throw const PreferenceSaveFailure('Gagal mengatur ulang preferensi. Coba lagi.');
    }
  }
}
