import 'package:ceklabel/models/family_profile.dart';
import 'package:ceklabel/models/ingredient.dart';
import 'package:ceklabel/models/risk_level.dart';
import 'package:ceklabel/models/scan_result.dart';
import 'package:ceklabel/services/detection_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _dictionary = [
  Ingredient(
    id: 'susu',
    name: 'Susu',
    aliases: ['susu bubuk', 'bubuk whey', 'whey', 'milk'],
    category: IngredientCategory.allergen,
    allergenGroup: 'Susu',
    description: 'Alergen susu.',
    riskLevelDefault: RiskLevel.danger,
  ),
  Ingredient(
    id: 'kacang',
    name: 'Kacang',
    aliases: ['kacang tanah', 'peanut'],
    category: IngredientCategory.allergen,
    allergenGroup: 'Kacang',
    description: 'Alergen kacang.',
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

  test('detects cross-contamination statement separately from direct ingredients', () {
    const raw = 'Biskuit Cokelat Krim\n'
        'Komposisi: Bubuk Whey, Maltodekstrin, Garam. '
        'Diproduksi di fasilitas yang juga memproses kacang tanah.';

    final direct = service.detect(rawText: raw, dictionary: _dictionary, selectedAllergens: {'Susu', 'Kacang'});
    final cross = service.detectCrossContamination(rawText: raw, dictionary: _dictionary);

    expect(direct.map((i) => i.ingredientId), isNot(contains('kacang')));
    expect(direct.map((i) => i.ingredientId), contains('susu'));
    expect(cross, isNotNull);
    expect(cross!.allergenGroups, ['Kacang']);
    expect(cross.statement.toLowerCase(), contains('kacang tanah'));
  });

  test('evaluates multi-profile impact with severe cross-contamination escalation', () {
    const raw = 'Biskuit Cokelat Krim\n'
        'Komposisi: Maltodekstrin, Garam. '
        'Diproduksi di fasilitas yang juga memproses kacang tanah.';
    final direct = service.detect(rawText: raw, dictionary: _dictionary, selectedAllergens: {'Kacang'});
    final cross = service.detectCrossContamination(rawText: raw, dictionary: _dictionary);
    final scan = ScanResult.create(
      rawText: raw,
      detected: direct,
      productName: service.guessProductName(raw),
      crossContamination: cross,
    );

    const profiles = [
      FamilyProfile(
        id: '1',
        name: 'Anak',
        role: 'Anak',
        allergens: {'Kacang'},
        sensitivity: SensitivityLevel.severe,
      ),
      FamilyProfile(
        id: '2',
        name: 'Ayah',
        role: 'Ayah',
        avoidHiddenSugar: true,
      ),
    ];

    final summary = service.summarize(scan, profiles);
    expect(scan.productName, 'Biskuit Cokelat Krim');
    expect(summary.overallLevel, RiskLevel.danger);
    expect(summary.impacts[0].level, RiskLevel.danger);
    expect(summary.impacts[0].label, contains('Kontaminasi Kacang'));
    expect(summary.impacts[1].level, RiskLevel.caution);
    expect(summary.impacts[1].label, contains('Gula Tersembunyi'));
  });

  test('guesses product name from first non-ingredient OCR line', () {
    expect(service.guessProductName('BISKUIT COKELAT KRIM\nKomposisi: Garam'), 'Biskuit Cokelat Krim');
    expect(service.guessProductName('Komposisi: Gula, Garam'), defaultProductName);
  });
}
