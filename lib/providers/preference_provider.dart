import 'package:flutter/foundation.dart';

import '../models/allergen_preference.dart';
import '../services/preference_service.dart';
import 'preference_status.dart';

class PreferenceProvider extends ChangeNotifier {
  // ignore: prefer_initializing_formals, intentional public param name
  PreferenceProvider({required PreferenceService service}) : _service = service;

  final PreferenceService _service;

  PreferenceStatus _status = PreferenceStatus.initial;
  AllergenPreference _preference = const AllergenPreference(
    userName: '',
    selectedAllergens: {},
  );
  String _errorMessage = '';

  PreferenceStatus get status => _status;
  AllergenPreference get preference => _preference;
  String get errorMessage => _errorMessage;

  Future<void> load() async {
    _status = PreferenceStatus.loading;
    _errorMessage = '';
    notifyListeners();
    try {
      _preference = await _service.loadPreferences();
      _status = PreferenceStatus.loaded;
    } catch (_) {
      _status = PreferenceStatus.error;
      _errorMessage = 'Gagal memuat preferensi. Coba lagi.';
    }
    notifyListeners();
  }

  void updateUserName(String value) {
    _preference = _preference.copyWith(userName: value);
    notifyListeners();
  }

  void toggleAllergen(String allergen) {
    final updated = Set<String>.from(_preference.selectedAllergens);
    if (updated.contains(allergen)) {
      updated.remove(allergen);
    } else {
      updated.add(allergen);
    }
    _preference = _preference.copyWith(selectedAllergens: updated);
    notifyListeners();
  }

  String? validateUserName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama wajib diisi';
    }
    if (value.trim().length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  String? validateAllergens() {
    if (_preference.selectedAllergens.isEmpty) {
      return 'Pilih minimal 1 alergen';
    }
    return null;
  }

  Future<bool> save() async {
    _status = PreferenceStatus.saving;
    _errorMessage = '';
    notifyListeners();
    try {
      await _service.savePreferences(_preference);
      _status = PreferenceStatus.success;
      notifyListeners();
      return true;
    } catch (_) {
      _status = PreferenceStatus.error;
      _errorMessage = 'Gagal menyimpan preferensi. Coba lagi.';
      notifyListeners();
      return false;
    }
  }
}
