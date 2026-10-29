import 'package:ceklabel/models/failures.dart';
import 'package:ceklabel/models/ingredient.dart';
import 'package:ceklabel/models/risk_level.dart';
import 'package:ceklabel/providers/scan_provider.dart';
import 'package:ceklabel/services/detection_service.dart';
import 'package:ceklabel/services/ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeOcrService extends OcrService {
  _FakeOcrService({this.mockPath = '/dummy/path.jpg', this.shouldFail = false});

  final String? mockPath;
  final bool shouldFail;

  @override
  Future<String?> pickImage(ScanSource source) async {
    if (shouldFail) {
      throw const OcrFailure('Kamera tidak dapat diakses.');
    }
    return mockPath;
  }

  @override
  Future<String> recognizeText(String imagePath) async {
    if (shouldFail) {
      throw const OcrFailure('Teks tidak terbaca.');
    }
    return 'Komposisi: susu, gula';
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const dictionary = [
    Ingredient(
      id: 'susu',
      name: 'Susu',
      aliases: ['milk'],
      category: IngredientCategory.allergen,
      allergenGroup: 'Susu',
      description: 'Alergen susu.',
      riskLevelDefault: RiskLevel.danger,
    ),
  ];

  test('scan berhasil memperbarui rawText, result, dan status success', () async {
    final ocrService = _FakeOcrService();
    final detectionService = DetectionService();
    final provider = ScanProvider(ocrService, detectionService);
    provider.updateDependencies(dictionary, {'Susu'});

    final result = await provider.scan(ScanSource.camera);

    expect(result, isNotNull);
    expect(provider.status, ScanStatus.success);
    expect(provider.rawText, 'Komposisi: susu, gula');
    expect(provider.result?.dangerCount, 1);
  });

  test('scan dibatalkan saat pengguna tidak memilih gambar', () async {
    final ocrService = _FakeOcrService(mockPath: null);
    final provider = ScanProvider(ocrService, DetectionService());

    final result = await provider.scan(ScanSource.gallery);

    expect(result, isNull);
    expect(provider.status, ScanStatus.initial);
    expect(provider.errorMessage, isNull);
  });

  test('scan menangani kegagalan OCR dan mengisi errorMessage', () async {
    final ocrService = _FakeOcrService(shouldFail: true);
    final provider = ScanProvider(ocrService, DetectionService());

    final result = await provider.scan(ScanSource.camera);

    expect(result, isNull);
    expect(provider.status, ScanStatus.error);
    expect(provider.errorMessage, 'Kamera tidak dapat diakses.');
  });

  test('summarize menghasilkan ringkasan risiko dan pesan yang akurat', () async {
    final provider = ScanProvider(_FakeOcrService(), DetectionService());
    provider.updateDependencies(dictionary, {'Susu'});
    final result = await provider.scan(ScanSource.camera);

    final summary = provider.summarize(result!);

    expect(summary.totalDetected, 1);
    expect(summary.dangerCount, 1);
    expect(summary.hasUserAllergen, isTrue);
    expect(summary.overallLevel, RiskLevel.danger);
    expect(summary.allergenGroups, contains('Susu'));
  });

  test('scan menyimpan ke riwayat dan loadHistory memuat kembali riwayat', () async {
    final provider = ScanProvider(_FakeOcrService(), DetectionService());
    provider.updateDependencies(dictionary, {'Susu'});

    await provider.scan(ScanSource.camera);
    expect(provider.history.length, 1);

    final secondProvider = ScanProvider(_FakeOcrService(), DetectionService());
    await secondProvider.loadHistory();
    expect(secondProvider.history.length, 1);
    expect(secondProvider.result?.id, provider.history.first.id);

    await secondProvider.clearHistory();
    expect(secondProvider.history, isEmpty);
    expect(secondProvider.result, isNull);
  });
}
