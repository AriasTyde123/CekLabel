import 'dart:convert';

import 'package:ceklabel/models/risk_level.dart';
import 'package:ceklabel/models/shopping_tips.dart';
import 'package:ceklabel/services/shopping_tip_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _sampleRequest = TipRequest(
  resultId: '1',
  productName: 'Biskuit Cokelat Krim',
  overallLevel: RiskLevel.danger,
  allergenGroups: ['Susu'],
  crossContaminationGroups: ['Kacang'],
  hasHiddenSugar: true,
  hasAdditives: true,
  riskyIngredients: ['Susu', 'Maltodekstrin'],
);

void main() {
  test('returns offline fallback tips when API key is missing', () async {
    final service = ShoppingTipService(apiKey: '');
    final result = await service.generate(_sampleRequest);

    expect(result.isOffline, isTrue);
    expect(result.tips, isNotEmpty);
    expect(result.tips.first.toLowerCase(), contains('bebas susu'));
  });

  test('parses structured Gemini JSON tips when online', () async {
    final client = MockClient((request) async {
      expect(request.headers['x-goog-api-key'], 'test-key');
      final payload = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'tips': [
                      "Cari biskuit berlabel 'bebas susu/dairy-free' tanpa bubuk whey.",
                      'Pilih varian tanpa gula tambahan dan pewarna sintetis.',
                    ],
                  }),
                },
              ],
            },
          },
        ],
      };
      return http.Response(jsonEncode(payload), 200);
    });

    final service = ShoppingTipService(client: client, apiKey: 'test-key');
    final result = await service.generate(_sampleRequest);

    expect(result.isOffline, isFalse);
    expect(result.tips.length, 2);
    expect(result.tips.first, contains('dairy-free'));
  });

  test('falls back to offline tips when Gemini API returns error', () async {
    final client = MockClient((_) async => http.Response('Internal Server Error', 500));
    final service = ShoppingTipService(client: client, apiKey: 'test-key');

    final result = await service.generate(_sampleRequest);
    expect(result.isOffline, isTrue);
    expect(result.tips, isNotEmpty);
  });
}

