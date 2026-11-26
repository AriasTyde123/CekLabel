import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/failures.dart';
import '../models/family_profile.dart';

class ProfileService {
  static const String profilesKey = 'family_profiles_v1';
  static const String legacyNameKey = 'preference_user_name';
  static const String legacyAllergensKey = 'preference_allergens';

  Future<List<FamilyProfile>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(profilesKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List;
        return [for (final item in decoded) FamilyProfile.fromJson(Map<String, dynamic>.from(item as Map))];
      }
      return await _migrateLegacy(prefs);
    } catch (_) {
      throw const ProfileLoadFailure();
    }
  }

  Future<void> save(List<FamilyProfile> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(profilesKey, jsonEncode([for (final p in profiles) p.toJson()]));
      if (!saved) throw const ProfileSaveFailure();
    } on ProfileSaveFailure {
      rethrow;
    } catch (_) {
      throw const ProfileSaveFailure();
    }
  }

  /// Converts the single-profile preference from the previous app version.
  Future<List<FamilyProfile>> _migrateLegacy(SharedPreferences prefs) async {
    final name = prefs.getString(legacyNameKey)?.trim() ?? '';
    final allergens = (prefs.getStringList(legacyAllergensKey) ?? const <String>[]).toSet();
    if (name.isEmpty && allergens.isEmpty) return const [];
    final profiles = [
      FamilyProfile(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.isEmpty ? 'Saya' : name,
        allergens: allergens.where(availableAllergens.contains).toSet(),
      ),
    ];
    await prefs.setString(profilesKey, jsonEncode([for (final p in profiles) p.toJson()]));
    await prefs.remove(legacyNameKey);
    await prefs.remove(legacyAllergensKey);
    return profiles;
  }
}

