import 'package:flutter/foundation.dart';

import '../models/failures.dart';
import '../models/ingredient.dart';
import '../models/risk_level.dart';
import '../models/scan_result.dart';
import '../services/detection_service.dart';
import '../services/history_service.dart';
import '../services/ocr_service.dart';

class ScanProvider extends ChangeNotifier {
  ScanProvider(this._ocrService, this._detectionService, [HistoryService? historyService])
      : _historyService = historyService ?? HistoryService();

  final OcrService _ocrService;
  final DetectionService _detectionService;
  final HistoryService _historyService;

  List<Ingredient> _dictionary = const [];
  Set<String> _allergens = const {};

  ScanStatus _status = ScanStatus.initial;
  String _rawText = '';
  ScanResult? _result;
  List<ScanResult> _history = const [];
  String? _errorMessage;

  ScanStatus get status => _status;
  String get rawText => _rawText;
  ScanResult? get result => _result;
  List<ScanResult> get history => _history;
  String? get errorMessage => _errorMessage;

  bool get isBusy =>
      _status == ScanStatus.pickingImage || _status == ScanStatus.recognizing || _status == ScanStatus.analyzing;

  Future<void> loadHistory() async {
    _history = await _historyService.load();
    if (_result == null && _history.isNotEmpty) {
      _result = _history.first;
    }
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _historyService.clear();
    _history = const [];
    _result = null;
    notifyListeners();
  }

  void selectResult(ScanResult result) {
    _result = result;
    _rawText = result.rawText;
    notifyListeners();
  }

  void updateDependencies(List<Ingredient> dictionary, Set<String> allergens) {
    _dictionary = dictionary;
    _allergens = allergens;
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
      _setStatus(ScanStatus.recognizing);
      _rawText = await _ocrService.recognizeText(path);
      _setStatus(ScanStatus.analyzing);
      final detected = _detectionService.detect(
        rawText: _rawText,
        dictionary: _dictionary,
        selectedAllergens: _allergens,
      );
      _result = ScanResult.create(rawText: _rawText, detected: detected);
      await _historyService.add(_result!);
      _history = await _historyService.load();
      _setStatus(ScanStatus.success);
      return _result;
    } on AppFailure catch (failure) {
      return _fail(failure.message);
    } catch (_) {
      return _fail('Terjadi kesalahan saat memindai. Coba lagi.');
    }
  }

  void reset() {
    _errorMessage = null;
    _setStatus(ScanStatus.initial);
  }

  ScanSummary summarize(ScanResult result) {
    final danger = result.detectedIngredients.where((item) => item.riskLevel == RiskLevel.danger).toList();
    final risky = result.dangerCount + result.cautionCount;
    final groups = danger.map((item) => item.allergenGroup).whereType<String>().toSet().toList();
    return ScanSummary(
      totalDetected: result.totalDetected,
      dangerCount: result.dangerCount,
      cautionCount: result.cautionCount,
      hasUserAllergen: danger.isNotEmpty,
      topRisks: danger.take(3).toList(),
      allergenGroups: groups,
      message: risky == 0 ? 'Tidak ada bahan berisiko terdeteksi' : 'Ditemukan $risky bahan berisiko',
    );
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
