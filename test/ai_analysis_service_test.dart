import 'dart:convert';
import 'dart:io';

import 'package:ceklabel/models/failures.dart';
import 'package:ceklabel/models/family_profile.dart';
import 'package:ceklabel/models/ingredient.dart';
import 'package:ceklabel/models/risk_level.dart';
import 'package:ceklabel/providers/scan_provider.dart';
import 'package:ceklabel/services/ai_analysis_service.dart';
import 'package:ceklabel/services/detection_service.dart';
import 'package:ceklabel/services/dictionary_service.dart';
import 'package:ceklabel/services/history_service.dart';
import 'package:ceklabel/services/ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubOcr implements OcrService {
  _StubOcr(this.text, {this.failRecognize = false, this.pickedPath = 'label.jpg'});

  final String text;
  final bool failRecognize;
  final String pickedPath;

  @override
  Future<String?> pickImage(ScanSource source) async => pickedPath;

  @override
  Future<String?> retrieveLostImagePath() async => null;

  @override
  Future<String> recognizeText(String imagePath) async {
    if (failRecognize) throw const OcrFailure('Pemindai teks tidak tersedia di perangkat ini.');
    return text;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  final dictionary = DictionaryService().parse(File('assets/ingredients.json').readAsStringSync());

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('AiAnalysisService parses structured JSON, fixes OCR typos, and explains new ingredients', () async {
    final client = MockClient((request) async {
      expect(request.headers['x-goog-api-key'], 'demo-key');
      final responsePayload = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'productName': 'Ramen Instan Pedas',
                    'brand': 'Tokyo Kitchen',
                    'ingredients': [
                      {
                        'name': 'Maltodekstrin',
                        'matchedKeyword': 'maltodekstrin',
                        'category': 'sugarAlias',
                        'allergenGroup': 'Gluten',
                        'isNonHalal': false,
                        'description': 'Gula tersembunyi dari pati.',
                      },
                      {
                        'name': 'Mirin',
                        'matchedKeyword': 'mirin',
                        'category': 'syubhat',
                        'allergenGroup': null,
                        'isNonHalal': true,
                        'description': 'Bumbu masak fermentasi beralkohol (non-halal).',
                      },
                      {
                        'name': 'Natrium Pirofosfat',
                        'matchedKeyword': 'natrium pirofosfat',
                        'category': 'additive',
                        'allergenGroup': null,
                        'isNonHalal': false,
                        'description': 'Zat pengemulsi dan pengembang untuk menjaga tekstur mi.',
                      },
                    ],
                    'crossContamination': {
                      'allergenGroups': ['Kacang'],
                      'statement': 'Diproduksi di fasilitas yang juga memproses kacang tanah.',
                    },
                  }),
                },
              ],
            },
          },
        ],
      };
      return http.Response(jsonEncode(responsePayload), 200);
    });

    final aiService = AiAnalysisService(client: client, apiKey: 'demo-key');
    final scanProvider = ScanProvider(
      _StubOcr('RAMEN INSTAN\nKomposisi: Maltodekstr1n, M1rin, Natrium Pirofosfat.'),
      DetectionService(),
      HistoryService(),
      aiService,
    );
    addTearDown(scanProvider.dispose);

    const halalProfile = FamilyProfile(id: 'p1', name: 'Ibu', role: 'Ibu', avoidSyubhat: true);
    scanProvider.updateDependencies(dictionary, const [halalProfile]);

    final result = await scanProvider.scan(ScanSource.camera);
    expect(result, isNotNull);
    expect(result!.isOfflineMode, isFalse);
    expect(result.productName, 'Ramen Instan Pedas');
    expect(result.brand, 'Tokyo Kitchen');
    expect(result.crossContamination?.allergenGroups, ['Kacang']);

    // New foreign ingredient outside local dictionary is preserved with dynamic AI description
    final newItem = result.detectedIngredients.firstWhere((i) => i.ingredientName == 'Natrium Pirofosfat');
    expect(newItem.ingredientId, 'ai-natrium-pirofosfat');
    expect(newItem.description, contains('pengemulsi'));

    // Non-halal ingredient escalates to Danger for profile with avoidSyubhat = true
    final summary = scanProvider.summarize(result);
    expect(summary.overallLevel, RiskLevel.danger);
    expect(summary.hasNonHalal, isTrue);
    expect(summary.impacts.single.label, 'Bahaya (Non-Halal)');
  });

  test('ScanProvider automatically falls back to local Mode Offline when Gemini API fails', () async {
    final failingClient = MockClient((_) async => http.Response('Service Unavailable', 503));
    final aiService = AiAnalysisService(client: failingClient, apiKey: 'demo-key');
    final scanProvider = ScanProvider(
      _StubOcr('Permen Stroberi\nKomposisi: Gula, Gelatin, Karmin, Garam'),
      DetectionService(),
      HistoryService(),
      aiService,
    );
    addTearDown(scanProvider.dispose);

    const halalProfile = FamilyProfile(id: 'p1', name: 'Ibu', role: 'Ibu', avoidSyubhat: true);
    scanProvider.updateDependencies(dictionary, const [halalProfile]);

    final result = await scanProvider.scan(ScanSource.gallery);
    expect(result, isNotNull);
    expect(result!.isOfflineMode, isTrue);
    expect(result.detectedIngredients.any((i) => i.category == IngredientCategory.syubhat), isTrue);

    final summary = scanProvider.summarize(result);
    expect(summary.overallLevel, RiskLevel.caution);
    expect(summary.hasSyubhat, isTrue);
    expect(summary.impacts.single.label, 'Waspada (Syubhat)');
  });

  test('ScanProvider uses Gemini Vision fallback when on-device ML Kit OCR is unavailable', () async {
    final tempFile = File('${Directory.systemTemp.path}/ceklabel_vision_test.jpg');
    tempFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);
    addTearDown(() {
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    final client = MockClient((request) async {
      final reqJson = jsonDecode(request.body) as Map<String, dynamic>;
      final parts = reqJson['contents'][0]['parts'] as List;
      expect(parts.first['inlineData']['mimeType'], 'image/jpeg');

      final responsePayload = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'extractedText': 'Susu Cokelat\nKomposisi: Susu Bubuk, Gula',
                    'productName': 'Susu Cokelat',
                    'brand': 'Segar',
                    'ingredients': [
                      {
                        'name': 'Susu',
                        'matchedKeyword': 'susu bubuk',
                        'category': 'allergen',
                        'allergenGroup': 'Susu',
                        'isNonHalal': false,
                        'description': 'Mengandung protein susu.',
                      },
                    ],
                    'crossContamination': null,
                  }),
                },
              ],
            },
          },
        ],
      };
      return http.Response(jsonEncode(responsePayload), 200);
    });

    final aiService = AiAnalysisService(client: client, apiKey: 'demo-key');
    final scanProvider = ScanProvider(
      _StubOcr('', failRecognize: true, pickedPath: tempFile.path),
      DetectionService(),
      HistoryService(),
      aiService,
    );
    addTearDown(scanProvider.dispose);

    const profile = FamilyProfile(id: 'p1', name: 'Anak', role: 'Anak', allergens: {'Susu'});
    scanProvider.updateDependencies(dictionary, const [profile]);

    final result = await scanProvider.scan(ScanSource.gallery);
    expect(result, isNotNull);
    expect(result!.isOfflineMode, isFalse);
    expect(result.productName, 'Susu Cokelat');
    expect(result.detectedIngredients.single.allergenGroup, 'Susu');
  });
}

