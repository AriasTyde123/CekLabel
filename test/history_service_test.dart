import 'package:ceklabel/models/detected_ingredient.dart';
import 'package:ceklabel/models/ingredient.dart';
import 'package:ceklabel/models/risk_level.dart';
import 'package:ceklabel/models/scan_result.dart';
import 'package:ceklabel/services/history_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('HistoryService menyimpan, memuat, membatasi max 10, dan membersihkan riwayat', () async {
    final service = HistoryService();
    expect(await service.load(), isEmpty);

    final item = ScanResult.create(
      rawText: 'Komposisi: susu',
      detected: [
        const DetectedIngredient(
          ingredientId: 'susu',
          ingredientName: 'Susu',
          matchedKeyword: 'susu',
          category: IngredientCategory.allergen,
          allergenGroup: 'Susu',
          riskLevel: RiskLevel.danger,
          description: 'Alergen susu.',
        ),
      ],
    );

    await service.add(item);
    final loaded = await service.load();
    expect(loaded.length, 1);
    expect(loaded.first.id, item.id);
    expect(loaded.first.rawText, 'Komposisi: susu');
    expect(loaded.first.detectedIngredients.first.ingredientName, 'Susu');

    await service.clear();
    expect(await service.load(), isEmpty);
  });
}
