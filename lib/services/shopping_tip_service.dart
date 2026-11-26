import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/failures.dart';
import '../models/risk_level.dart';
import '../models/shopping_tips.dart';

/// Generates generic shopping tips with Gemini, falling back to local rules when offline.
class ShoppingTipService {
  ShoppingTipService({http.Client? client, String? apiKey})
      : _client = client,
        _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY');

  static const String model = 'gemini-2.5-flash';
  static const Duration timeout = Duration(seconds: 8);
  static const int maxTips = 3;

  http.Client? _client;
  final String _apiKey;

  http.Client get _httpClient => _client ??= http.Client();

  bool get hasApiKey => _apiKey.isNotEmpty;

  Future<ShoppingTips> generate(TipRequest request) async {
    if (!hasApiKey) return ShoppingTips(tips: localTips(request), isOffline: true);
    try {
      final tips = await _fetchOnline(request);
      return ShoppingTips(tips: tips, isOffline: false);
    } catch (_) {
      return ShoppingTips(tips: localTips(request), isOffline: true);
    }
  }

  /// Rule-based tips used when Gemini is unavailable.
  List<String> localTips(TipRequest request) {
    const allergenTips = {
      'Susu': "Cari label 'bebas susu/dairy-free' dan hindari whey, kasein, mentega, atau susu bubuk di komposisi.",
      'Kacang': "Pilih produk berlabel 'bebas kacang' dan hindari minyak kacang atau pasta kacang.",
      'Gluten': "Cari label 'bebas gluten/gluten-free' atau produk berbahan tepung beras, jagung, atau singkong.",
      'Telur': 'Hindari produk dengan putih telur, kuning telur, atau albumin; cari kue tanpa telur (eggless).',
      'Udang': 'Hindari bumbu dengan ekstrak udang, terasi, atau rebon; pilih perisa berbahan nabati.',
      'Kedelai': "Cari pengemulsi selain lesitin kedelai, misalnya lesitin bunga matahari, atau label 'bebas kedelai'.",
    };
    final tips = <String>[
      for (final group in request.allergenGroups)
        if (allergenTips[group] != null) allergenTips[group]!,
      if (request.crossContaminationGroups.isNotEmpty)
        "Untuk alergi berat, pilih produk yang tidak mencantumkan peringatan 'dapat mengandung "
            "${request.crossContaminationGroups.join(', ').toLowerCase()}'.",
      if (request.hasSyubhat)
        'Pilih produk dengan logo Halal resmi dan hindari gelatin, karmin (E120), E471 tanpa keterangan nabati, mirin, atau lemak hewani.',
      if (request.hasHiddenSugar)
        "Pilih varian berlabel 'tanpa gula tambahan' dan pastikan gula tidak berada di urutan awal komposisi.",
      if (request.hasAdditives)
        'Pilih produk tanpa pewarna sintetis (seperti tartrazin/E102) dan tanpa MSG; utamakan pewarna alami.',
    ];
    if (tips.isEmpty) {
      tips.add(request.overallLevel == RiskLevel.safe
          ? 'Produk ini tampak sesuai profil aktif. Tetap cek ulang label karena resep produsen bisa berubah.'
          : 'Bandingkan komposisi dengan produk sejenis dan pilih yang daftar bahannya lebih pendek dan sederhana.');
    }
    return tips.take(maxTips).toList();
  }

  Future<List<String>> _fetchOnline(TipRequest request) async {
    final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');
    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': _prompt(request)},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.4,
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'tips': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'},
            },
          },
          'required': ['tips'],
        },
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
    if (response.statusCode != 200) throw AiFailure('Layanan AI menolak permintaan (${response.statusCode}).');

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final text = decoded['candidates'][0]['content']['parts'][0]['text'] as String;
      final tips = List<String>.from((jsonDecode(text) as Map<String, dynamic>)['tips'] as List)
          .map((tip) => tip.trim())
          .where((tip) => tip.isNotEmpty)
          .take(maxTips)
          .toList();
      if (tips.isEmpty) throw const AiFailure('Jawaban AI kosong.');
      return tips;
    } on AiFailure {
      rethrow;
    } catch (_) {
      throw const AiFailure('Jawaban AI tidak dapat dibaca.');
    }
  }

  String _prompt(TipRequest request) {
    String list(List<String> items) => items.isEmpty ? '-' : items.join(', ');
    return 'Kamu adalah asisten belanja makanan sehat untuk keluarga di Indonesia. '
        'Berdasarkan hasil analisis label berikut, berikan 2-3 tips belanja alternatif yang generik dan praktis '
        'dalam bahasa Indonesia yang mudah dipahami (maksimal 25 kata per tips). '
        'JANGAN menyebut merek atau nama produk tertentu. Sarankan ciri label yang perlu dicari atau dihindari.\n'
        'Status: ${request.overallLevel.headline}\n'
        'Alergen yang terdeteksi dan dihindari profil: ${list(request.allergenGroups)}\n'
        'Risiko kontaminasi silang: ${list(request.crossContaminationGroups)}\n'
        'Gula tersembunyi: ${request.hasHiddenSugar ? 'ya' : 'tidak'}\n'
        'Zat aditif/pewarna: ${request.hasAdditives ? 'ya' : 'tidak'}\n'
        'Bahan syubhat/non-halal: ${request.hasSyubhat ? 'ya' : 'tidak'}\n'
        'Bahan berisiko: ${list(request.riskyIngredients)}';
  }

  void dispose() => _client?.close();
}

