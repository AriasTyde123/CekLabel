import 'package:ceklabel/models/ingredient.dart';
import 'package:ceklabel/models/risk_level.dart';
import 'package:ceklabel/services/detection_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _dictionary = [
  Ingredient(
    id: 'susu',
    name: 'Susu',
    aliases: ['susu bubuk', 'milk'],
    category: IngredientCategory.allergen,
    allergenGroup: 'Susu',
    description: 'Alergen susu.',
    riskLevelDefault: RiskLevel.danger,
  ),
  Ingredient(
    id: 'maltodekstrin',
    name: 'Maltodekstrin',
    aliases: ['maltodextrin'],
    category: IngredientCategory.sugarAlias,
    allergenGroup: 'Gluten',
    description: 'Gula tersembunyi.',
    riskLevelDefault: RiskLevel.caution,
  ),
  Ingredient(
    id: 'garam',
    name: 'Garam',
    aliases: [],
    category: IngredientCategory.other,
    allergenGroup: null,
    description: 'Natrium.',
    riskLevelDefault: RiskLevel.safe,
  ),
];

void main() {
  final service = DetectionService();

  test('escalates to danger when allergen group is selected', () {
    final result = service.detect(
      rawText: 'Komposisi: Susu Bubuk, garam',
      dictionary: _dictionary,
      selectedAllergens: {'Susu'},
    );
    expect(result.first.ingredientId, 'susu');
    expect(result.first.riskLevel, RiskLevel.danger);
    expect(result.first.matchedKeyword, 'susu bubuk');
  });

  test('marks hidden sugar as caution without allergen match', () {
    final result = service.detect(
      rawText: 'Maltodekstrin,\nGaram',
      dictionary: _dictionary,
      selectedAllergens: {'Susu'},
    );
    expect(result.map((item) => item.riskLevel), [RiskLevel.caution, RiskLevel.safe]);
  });

  test('does not match inside longer words and returns empty for blank text', () {
    expect(service.detect(rawText: 'susunan bahan', dictionary: _dictionary, selectedAllergens: {'Susu'}), isEmpty);
    expect(service.detect(rawText: '   ', dictionary: _dictionary, selectedAllergens: {}), isEmpty);
  });
}
