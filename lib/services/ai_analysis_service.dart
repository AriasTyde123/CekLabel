import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/cross_contamination.dart';
import '../models/detected_ingredient.dart';
import '../models/failures.dart';
import '../models/family_profile.dart';
import '../models/ingredient.dart';
import '../models/risk_level.dart';
import '../models/scan_result.dart';
import 'detection_service.dart';

class AiAnalysisOutput {
  const AiAnalysisOutput({
    required this.productName,
    required this.brand,
    required this.ingredients,
    required this.crossContamination,
    this.extractedText = '',
  });

  final String productName;
  final String brand;
  final List<DetectedIngredient> ingredients;
  final CrossContamination? crossContamination;
  final String extractedText;
}

/// Analyzes raw OCR label text via Gemini Structured JSON Output.
/// Fixes OCR typos, interprets cross-contamination context, and explains new/foreign ingredients.
class AiAnalysisService {
  AiAnalysisService({
    http.Client? client,
    String? apiKey,
    DetectionService? detectionService,
  })  : _client = client,
        _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
        _detectionService = detectionService ?? DetectionService();

  static const String model = 'gemini-2.5-flash';
  static const Duration timeout = Duration(seconds: 12);

  http.Client? _client;
  final String _apiKey;
  final DetectionService _detectionService;

  http.Client get _httpClient => _client ??= http.Client();

  bool get hasApiKey => _apiKey.isNotEmpty;

  Future<AiAnalysisOutput> analyze({
    required String rawText,
    required List<Ingredient> dictionary,
    required Set<String> selectedAllergens,
    required bool avoidSyubhat,
  }) async {
    if (!hasApiKey) throw const AiFailure('API key Gemini belum dikonfigurasi.');

    final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');
    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': _prompt(rawText)},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1,
        'responseMimeType': 'application/json',
        'responseSchema': _schema,
      },
    };

    final http.Response response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'x-goog-api-key': _apiKey},
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } catch (_) {
      throw const AiFailure('Tidak dapat terhubung ke layanan AI.');
    }

    if (response.statusCode != 200) {
      throw AiFailure('Layanan AI menolak permintaan (${response.statusCode}).');
    }

    try {
      final outer = jsonDecode(response.body) as Map<String, dynamic>;
      final text = outer['candidates'][0]['content']['parts'][0]['text'] as String;
      final data = jsonDecode(text) as Map<String, dynamic>;
      return _parseOutput(
        data,
        rawText: rawText,
        dictionary: dictionary,
        selectedAllergens: selectedAllergens,
        avoidSyubhat: avoidSyubhat,
      );
    } on AiFailure {
      rethrow;
    } catch (_) {
      throw const AiFailure('Format hasil analisis AI tidak valid.');
    }
  }

  /// Multimodal fallback: reads and analyzes a label image directly when on-device ML Kit OCR is unavailable.
  Future<AiAnalysisOutput> analyzeImage({
    required Uint8List imageBytes,
    required String mimeType,
    required List<Ingredient> dictionary,
    required Set<String> selectedAllergens,
    required bool avoidSyubhat,
  }) async {
    if (!hasApiKey) throw const AiFailure('API key Gemini belum dikonfigurasi.');

    final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');
    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
            {'text': _imagePrompt()},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1,
        'responseMimeType': 'application/json',
        'responseSchema': _imageSchema,
      },
    };

    final http.Response response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'x-goog-api-key': _apiKey},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const AiFailure('Tidak dapat terhubung ke layanan AI.');
    }

    if (response.statusCode != 200) {
      throw AiFailure('Layanan AI menolak permintaan (${response.statusCode}).');
    }

    try {
      final outer = jsonDecode(response.body) as Map<String, dynamic>;
      final text = outer['candidates'][0]['content']['parts'][0]['text'] as String;
      final data = jsonDecode(text) as Map<String, dynamic>;
      final extracted = (data['extractedText'] as String?)?.trim() ?? '';
      return _parseOutput(
        data,
        rawText: extracted,
        dictionary: dictionary,
        selectedAllergens: selectedAllergens,
        avoidSyubhat: avoidSyubhat,
      );
    } on AiFailure {
      rethrow;
    } catch (_) {
      throw const AiFailure('Format hasil analisis AI tidak valid.');
    }
  }

  AiAnalysisOutput _parseOutput(
    Map<String, dynamic> data, {
    required String rawText,
    required List<Ingredient> dictionary,
    required Set<String> selectedAllergens,
    required bool avoidSyubhat,
  }) {
    final rawName = (data['productName'] as String?)?.trim() ?? '';
    final productName = rawName.isEmpty ? _detectionService.guessProductName(rawText) : rawName;
    final brand = (data['brand'] as String?)?.trim() ?? '';

    final seen = <String>{};
    final ingredients = <DetectedIngredient>[];
    for (final rawItem in data['ingredients'] as List? ?? const []) {
      final map = Map<String, dynamic>.from(rawItem as Map);
      final name = (map['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) continue;

      final matched = (map['matchedKeyword'] as String?)?.trim() ?? '';
      final localMatch = _matchDictionary(name, matched, dictionary);
      final id = localMatch?.id ?? 'ai-${_slug(name)}';
      if (!seen.add(id)) continue;

      final category = IngredientCategory.values.asNameMap()[map['category']] ??
          localMatch?.category ??
          IngredientCategory.other;
      final rawGroup = (map['allergenGroup'] as String?)?.trim();
      final allergenGroup = (rawGroup != null && availableAllergens.contains(rawGroup))
          ? rawGroup
          : localMatch?.allergenGroup;
      final isNonHalal = (map['isNonHalal'] as bool? ?? false) ||
          (localMatch?.category == IngredientCategory.syubhat && localMatch?.riskLevelDefault == RiskLevel.danger);
      final rawDescription = (map['description'] as String?)?.trim() ?? '';
      final description = rawDescription.isNotEmpty
          ? rawDescription
          : (localMatch?.description ?? 'Bahan pangan yang tercantum pada label komposisi.');

      ingredients.add(DetectedIngredient(
        ingredientId: id,
        ingredientName: localMatch?.name ?? name,
        matchedKeyword: matched.isNotEmpty ? matched : name.toLowerCase(),
        category: category,
        allergenGroup: allergenGroup,
        riskLevel: _detectionService.resolveRisk(
          category,
          allergenGroup,
          selectedAllergens,
          avoidSyubhat: avoidSyubhat,
          isNonHalal: isNonHalal,
        ),
        description: description,
        isNonHalal: isNonHalal,
      ));
    }

    ingredients.sort((a, b) {
      final byRisk = a.riskLevel.index.compareTo(b.riskLevel.index);
      return byRisk != 0 ? byRisk : a.ingredientName.compareTo(b.ingredientName);
    });

    CrossContamination? cross;
    final rawCross = data['crossContamination'];
    if (rawCross is Map) {
      final crossMap = Map<String, dynamic>.from(rawCross);
      final statement = (crossMap['statement'] as String?)?.trim() ?? '';
      final groups = List<String>.from(crossMap['allergenGroups'] as List? ?? const [])
          .where(availableAllergens.contains)
          .toSet();
      final ordered = [for (final g in availableAllergens) if (groups.contains(g)) g];
      if (statement.isNotEmpty) {
        cross = CrossContamination(allergenGroups: ordered, statement: statement);
      }
    }
    cross ??= _detectionService.detectCrossContamination(rawText: rawText, dictionary: dictionary);

    return AiAnalysisOutput(
      productName: productName.isEmpty ? defaultProductName : productName,
      brand: brand,
      ingredients: ingredients,
      crossContamination: cross,
      extractedText: rawText,
    );
  }

  Ingredient? _matchDictionary(String name, String matched, List<Ingredient> dictionary) {
    final probes = {
      _detectionService.normalize(name),
      if (matched.isNotEmpty) _detectionService.normalize(matched),
    };
    for (final item in dictionary) {
      for (final keyword in item.keywords) {
        if (probes.contains(_detectionService.normalize(keyword))) return item;
      }
    }
    return null;
  }

  String _slug(String value) {
    final cleaned = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    return cleaned.isEmpty ? 'bahan' : cleaned;
  }

  String _prompt(String rawText) {
    return 'Kamu adalah ahli keamanan pangan dan penerjemah label komposisi makanan untuk aplikasi CekLabel di Indonesia.\n'
        'Analisis teks hasil OCR kemasan berikut:\n'
        '"""\n$rawText\n"""\n\n'
        'Tugasmu:\n'
        '1. Perbaiki typo hasil OCR pada nama bahan (mis. "Maltodekstr1n" -> "Maltodekstrin", "Wh3y" -> "Bubuk Whey").\n'
        '2. Tebak "productName" dan "brand" jika terlihat di teks, jika tidak kosongkan ("").\n'
        '3. Daftarkan bahan komposisi utama ke array "ingredients" (JANGAN masukkan bahan yang hanya muncul di kalimat peringatan "dapat mengandung / may contain").\n'
        '   Untuk tiap bahan:\n'
        '   - "name": nama bahan bersih dalam Bahasa Indonesia.\n'
        '   - "matchedKeyword": teks bahan yang sudah dibersihkan dari label.\n'
        '   - "category": salah satu dari: "allergen", "sugarAlias", "additive", "preservative", "coloring", "sweetener", "syubhat", "other".\n'
        '     Gunakan "syubhat" untuk bahan non-halal (babi/lard/pork/alkohol/mirin/angciu/rhum) atau syubhat (gelatin tanpa keterangan halal, karmin/E120, E471, rennet, lemak hewani).\n'
        '   - "isNonHalal": true HANYA jika jelas non-halal (babi, lard, pork, alkohol, mirin, angciu, rhum, wine), false untuk lainnya.\n'
        '   - "allergenGroup": salah satu dari "Kacang", "Susu", "Gluten", "Telur", "Udang", "Kedelai", atau null jika bukan 6 alergen tersebut.\n'
        '   - "description": penjelasan singkat 1-2 kalimat dalam bahasa Indonesia awam.\n'
        '4. Jika ada kalimat kontaminasi silang ("dapat mengandung", "diproduksi di fasilitas yang sama", "may contain"), isi "crossContamination" dengan daftar "allergenGroups" dan kalimat "statement" yang rapi dalam Bahasa Indonesia. Jika tidak ada, isi null.';
  }

  static const Map<String, Object> _schema = {
    'type': 'OBJECT',
    'properties': {
      'productName': {'type': 'STRING'},
      'brand': {'type': 'STRING'},
      'ingredients': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'name': {'type': 'STRING'},
            'matchedKeyword': {'type': 'STRING'},
            'category': {
              'type': 'STRING',
              'enum': ['allergen', 'sugarAlias', 'additive', 'preservative', 'coloring', 'sweetener', 'syubhat', 'other'],
            },
            'allergenGroup': {'type': 'STRING', 'nullable': true},
            'isNonHalal': {'type': 'BOOLEAN'},
            'description': {'type': 'STRING'},
          },
          'required': ['name', 'matchedKeyword', 'category', 'isNonHalal', 'description'],
        },
      },
      'crossContamination': {
        'type': 'OBJECT',
        'nullable': true,
        'properties': {
          'allergenGroups': {
            'type': 'ARRAY',
            'items': {'type': 'STRING'},
          },
          'statement': {'type': 'STRING'},
        },
        'required': ['allergenGroups', 'statement'],
      },
    },
    'required': ['productName', 'brand', 'ingredients'],
  };

  String _imagePrompt() {
    return 'Kamu adalah ahli keamanan pangan dan penerjemah label komposisi makanan untuk aplikasi CekLabel di Indonesia.\n'
        'Baca teks komposisi makanan dari foto kemasan ini, lalu keluarkan JSON terstruktur.\n'
        'Tugasmu:\n'
        '1. Tulis transkripsi teks komposisi yang terbaca pada gambar ke "extractedText".\n'
        '2. Tebak "productName" dan "brand" jika terlihat di kemasan, jika tidak kosongkan ("").\n'
        '3. Daftarkan bahan komposisi utama ke array "ingredients" (JANGAN masukkan bahan yang hanya muncul di kalimat peringatan "dapat mengandung / may contain").\n'
        '   Untuk tiap bahan:\n'
        '   - "name": nama bahan bersih dalam Bahasa Indonesia.\n'
        '   - "matchedKeyword": teks bahan dari label.\n'
        '   - "category": salah satu dari: "allergen", "sugarAlias", "additive", "preservative", "coloring", "sweetener", "syubhat", "other".\n'
        '   - "isNonHalal": true HANYA jika jelas non-halal (babi, lard, pork, alkohol, mirin, angciu, rhum, wine), false untuk lainnya.\n'
        '   - "allergenGroup": salah satu dari "Kacang", "Susu", "Gluten", "Telur", "Udang", "Kedelai", atau null.\n'
        '   - "description": penjelasan singkat 1-2 kalimat dalam bahasa Indonesia awam.\n'
        '4. Jika ada kalimat kontaminasi silang ("dapat mengandung", "diproduksi di fasilitas yang sama", "may contain"), isi "crossContamination". Jika tidak ada, isi null.';
  }

  static const Map<String, Object> _imageSchema = {
    'type': 'OBJECT',
    'properties': {
      'extractedText': {'type': 'STRING'},
      'productName': {'type': 'STRING'},
      'brand': {'type': 'STRING'},
      'ingredients': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'name': {'type': 'STRING'},
            'matchedKeyword': {'type': 'STRING'},
            'category': {
              'type': 'STRING',
              'enum': ['allergen', 'sugarAlias', 'additive', 'preservative', 'coloring', 'sweetener', 'syubhat', 'other'],
            },
            'allergenGroup': {'type': 'STRING', 'nullable': true},
            'isNonHalal': {'type': 'BOOLEAN'},
            'description': {'type': 'STRING'},
          },
          'required': ['name', 'matchedKeyword', 'category', 'isNonHalal', 'description'],
        },
      },
      'crossContamination': {
        'type': 'OBJECT',
        'nullable': true,
        'properties': {
          'allergenGroups': {
            'type': 'ARRAY',
            'items': {'type': 'STRING'},
          },
          'statement': {'type': 'STRING'},
        },
        'required': ['allergenGroups', 'statement'],
      },
    },
    'required': ['extractedText', 'productName', 'brand', 'ingredients'],
  };

  void dispose() => _client?.close();
}

