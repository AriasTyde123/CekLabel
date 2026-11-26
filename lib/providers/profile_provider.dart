import 'package:flutter/foundation.dart';

import '../models/failures.dart';
import '../models/family_profile.dart';
import '../services/profile_service.dart';

enum ProfileStatus { initial, loading, loaded, saving, error }

class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._service);

  final ProfileService _service;

  ProfileStatus _status = ProfileStatus.initial;
  List<FamilyProfile> _profiles = const [];
  String? _errorMessage;

  ProfileStatus get status => _status;
  List<FamilyProfile> get profiles => List.unmodifiable(_profiles);
  List<FamilyProfile> get activeProfiles => List.unmodifiable(_profiles.where((p) => p.isActive));
  Set<String> get activeAllergens => {for (final p in activeProfiles) ...p.allergens};
  String? get errorMessage => _errorMessage;
  bool get isBusy => _status == ProfileStatus.loading || _status == ProfileStatus.saving;

  FamilyProfile? findById(String id) {
    for (final profile in _profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> load() async {
    _status = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _profiles = await _service.load();
      _status = ProfileStatus.loaded;
    } on AppFailure catch (failure) {
      _errorMessage = failure.message;
      _status = ProfileStatus.error;
    }
    notifyListeners();
  }

  /// Adds a new profile or replaces the one with the same id.
  Future<bool> saveProfile(FamilyProfile profile) async {
    final cleaned = profile.copyWith(name: profile.name.trim());
    if (validateName(cleaned.name) != null || validateFilters(cleaned) != null) return false;
    final exists = _profiles.any((p) => p.id == cleaned.id);
    return _persist([
      if (exists) for (final p in _profiles) p.id == cleaned.id ? cleaned : p else ...[..._profiles, cleaned],
    ]);
  }

  Future<bool> deleteProfile(String id) => _persist(_profiles.where((p) => p.id != id).toList());

  Future<bool> toggleActive(String id) => _persist([
        for (final p in _profiles) p.id == id ? p.copyWith(isActive: !p.isActive) : p,
      ]);

  static String? validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Nama wajib diisi';
    if (trimmed.length < 2) return 'Nama minimal 2 karakter';
    if (trimmed.length > 24) return 'Nama maksimal 24 karakter';
    return null;
  }

  static String? validateFilters(FamilyProfile profile) =>
      profile.hasAnyFilter ? null : 'Pilih minimal 1 alergen atau filter tambahan';

  Future<bool> _persist(List<FamilyProfile> updated) async {
    final previous = _profiles;
    _profiles = updated;
    _status = ProfileStatus.saving;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.save(updated);
      _status = ProfileStatus.loaded;
      notifyListeners();
      return true;
    } on AppFailure catch (failure) {
      _profiles = previous;
      _errorMessage = failure.message;
      _status = ProfileStatus.error;
      notifyListeners();
      return false;
    }
  }
}

