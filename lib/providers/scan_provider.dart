import 'package:flutter/foundation.dart';

import '../models/failures.dart';
import '../models/family_profile.dart';
import '../models/ingredient.dart';
import '../models/risk_level.dart';
import '../models/scan_result.dart';
import '../services/ai_analysis_service.dart';
import '../services/detection_service.dart';
import '../services/history_service.dart';
import '../services/ocr_service.dart';

class ScanProvider extends ChangeNotifier {
  ScanProvider(
    this._ocrService,
    this._detectionService, [
    HistoryService? historyService,
    AiAnalysisService? aiService,
  ])  : _historyService = historyService ?? HistoryService(),
        _aiService = aiService;

  final OcrService _ocrService;
  final DetectionService _detectionService;
  final HistoryService _historyService;
  final AiAnalysisService? _aiService;

  List<Ingredient> _dictionary = const [];
  List<FamilyProfile> _profiles = const [];

  ScanStatus _status = ScanStatus.initial;
  String _rawText = '';
  List<ScanResult> _history = [];
  String? _errorMessage;
  String? _storageError;

  ScanStatus get status => _status;
  String get rawText => _rawText;
  List<ScanResult> get history => List.unmodifiable(_history);
  List<ScanResult> get savedResults => List.unmodifiable(_history.where((r) => r.isSaved));
  String? get errorMessage => _errorMessage;

  /// Last persistence error (history keeps working in memory).
  String? get storageError => _storageError;

  bool get isBusy =>
      _status == ScanStatus.pickingImage || _status == ScanStatus.recognizing || _status == ScanStatus.analyzing;

  Set<String> get _allergens => {for (final profile in _profiles) ...profile.allergens};
  bool get _avoidSyubhat => _profiles.any((profile) => profile.avoidSyubhat);

  void updateDependencies(List<Ingredient> dictionary, List<FamilyProfile> activeProfiles) {
    _dictionary = dictionary;
    _profiles = activeProfiles;
  }

  ScanResult? findById(String id) {
    for (final result in _history) {
      if (result.id == id) return result;
    }
    return null;
  }

  Future<void> loadHistory() async {
    try {
      final loaded = await _historyService.load();
      final known = _history.map((r) => r.id).toSet();
      _history = [..._history, ...loaded.where((r) => !known.contains(r.id))];
      _storageError = null;
    } on AppFailure catch (failure) {
      _storageError = failure.message;
    }
    notifyListeners();
  }

  Future<ScanResult?> scan(ScanSource source) async {
    if (isBusy) return null;
    _errorMessage = null;
    _setStatus(ScanStatus.pickingImage);
    try {
      final path = await _ocrService.pickImage(source);
      if (path == null) {
        _setStatus(ScanStatus.initial);
        return null;
      }
      return await _analyzeImage(path);
    } on AppFailure catch (failure) {
      return _fail(failure.message);
    } catch (_) {
      return _fail('Terjadi kesalahan saat memindai. Coba lagi.');
    }
  }

  /// Runs OCR, ingredient detection, and history persistence on an already captured image file.
  Future<ScanResult?> scanImageFile(String imagePath) async {
    if (isBusy) return null;
    _errorMessage = null;
    try {
      return await _analyzeImage(imagePath);
    } on AppFailure catch (failure) {
      return _fail(failure.message);
    } catch (_) {
      return _fail('Terjadi kesalahan saat memindai. Coba lagi.');
    }
  }

  Future<ScanResult> _analyzeImage(String path) async {
    _setStatus(ScanStatus.recognizing);
    _rawText = await _ocrService.recognizeText(path);
    _setStatus(ScanStatus.analyzing);

    ScanResult? result;
    final ai = _aiService;
    if (ai != null && ai.hasApiKey) {
      try {
        final output = await ai.analyze(
          rawText: _rawText,
          dictionary: _dictionary,
          selectedAllergens: _allergens,
          avoidSyubhat: _avoidSyubhat,
        );
        result = ScanResult.create(
          rawText: _rawText,
          detected: output.ingredients,
          productName: output.productName,
          brand: output.brand,
          crossContamination: output.crossContamination,
          isOfflineMode: false,
        );
      } catch (_) {
        // Automatic graceful offline fallback when AI fails, times out, or device is offline.
      }
    }

    result ??= ScanResult.create(
      rawText: _rawText,
      detected: _detectionService.detect(
        rawText: _rawText,
        dictionary: _dictionary,
        selectedAllergens: _allergens,
        avoidSyubhat: _avoidSyubhat,
      ),
      productName: _detectionService.guessProductName(_rawText),
      crossContamination: _detectionService.detectCrossContamination(rawText: _rawText, dictionary: _dictionary),
      isOfflineMode: true,
    );

    _history.insert(0, result);
    await _persist();
    _setStatus(ScanStatus.success);
    return result;
  }

  /// Adds or removes a result from the Safe List. Returns false if storage failed.
  Future<bool> toggleSaved(String id) async {
    final result = findById(id);
    if (result == null) return false;
    return _replace(result.copyWith(isSaved: !result.isSaved));
  }

  Future<bool> updateProductInfo(String id, {required String productName, required String brand}) async {
    final result = findById(id);
    if (result == null) return false;
    final name = productName.trim();
    return _replace(result.copyWith(productName: name.isEmpty ? defaultProductName : name, brand: brand.trim()));
  }

  void reset() {
    _errorMessage = null;
    _setStatus(ScanStatus.initial);
  }

  ScanSummary summarize(ScanResult result) => _detectionService.summarize(result, _profiles);

  Future<bool> _replace(ScanResult updated) async {
    final previous = _history;
    _history = [for (final r in _history) r.id == updated.id ? updated : r];
    notifyListeners();
    final ok = await _persist();
    if (!ok) {
      _history = previous;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> _persist() async {
    try {
      await _historyService.save(_history);
      _storageError = null;
      return true;
    } on AppFailure catch (failure) {
      _storageError = failure.message;
      return false;
    }
  }

  ScanResult? _fail(String message) {
    _errorMessage = message;
    _setStatus(ScanStatus.error);
    return null;
  }

  void _setStatus(ScanStatus value) {
    _status = value;
    notifyListeners();
  }
}
