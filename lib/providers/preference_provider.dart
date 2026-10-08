import 'package:flutter/foundation.dart';

import '../models/allergen_preference.dart';
import '../models/failures.dart';
import '../services/preference_service.dart';
import 'preference_status.dart';

class PreferenceProvider extends ChangeNotifier {
  PreferenceProvider(this._service);

  final PreferenceService _service;

  PreferenceStatus _status = PreferenceStatus.initial;
  AllergenPreference _saved = const AllergenPreference();
  AllergenPreference _draft = const AllergenPreference();
  String? _nameError;
  String? _allergenError;
  String? _errorMessage;

  PreferenceStatus get status => _status;
  String get userName => _draft.userName;
  Set<String> get selectedAllergens => Set.unmodifiable(_draft.selectedAllergens);
  Set<String> get savedAllergens => Set.unmodifiable(_saved.selectedAllergens);
  String get savedUserName => _saved.userName;
  String? get nameError => _nameError;
  String? get allergenError => _allergenError;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _status == PreferenceStatus.loading || _status == PreferenceStatus.saving;

  Future<void> load() async {
    _status = PreferenceStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _saved = await _service.load();
      _draft = _saved;
      _status = PreferenceStatus.loaded;
    } on AppFailure catch (failure) {
      _errorMessage = failure.message;
      _status = PreferenceStatus.error;
    }
    notifyListeners();
  }

  void setUserName(String value) {
    _draft = _draft.copyWith(userName: value);
    if (_nameError != null) _nameError = _validateName(value);
    notifyListeners();
  }

  void toggleAllergen(String allergen, bool selected) {
    final updated = {..._draft.selectedAllergens};
    selected ? updated.add(allergen) : updated.remove(allergen);
    _draft = _draft.copyWith(selectedAllergens: updated);
    if (_allergenError != null) _allergenError = _validateAllergens(updated);
    notifyListeners();
  }

  bool validate() {
    _nameError = _validateName(_draft.userName);
    _allergenError = _validateAllergens(_draft.selectedAllergens);
    notifyListeners();
    return _nameError == null && _allergenError == null;
  }

  Future<bool> save() async {
    if (!validate()) return false;
    _status = PreferenceStatus.saving;
    _errorMessage = null;
    notifyListeners();
    try {
      final cleaned = _draft.copyWith(userName: _draft.userName.trim());
      await _service.save(cleaned);
      _saved = cleaned;
      _draft = cleaned;
      _status = PreferenceStatus.success;
      notifyListeners();
      return true;
    } on AppFailure catch (failure) {
      _errorMessage = failure.message;
      _status = PreferenceStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reset() async {
    try {
      await _service.clear();
      _saved = const AllergenPreference();
      _draft = _saved;
      _nameError = null;
      _allergenError = null;
      _errorMessage = null;
      _status = PreferenceStatus.loaded;
      notifyListeners();
      return true;
    } on AppFailure catch (failure) {
      _errorMessage = failure.message;
      _status = PreferenceStatus.error;
      notifyListeners();
      return false;
    }
  }

  String? _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Nama wajib diisi';
    if (trimmed.length < 3) return 'Nama minimal 3 karakter';
    return null;
  }

  String? _validateAllergens(Set<String> allergens) => allergens.isEmpty ? 'Pilih minimal 1 alergen' : null;
}
