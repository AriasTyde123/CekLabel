import '../models/detected_ingredient.dart';
import '../models/ingredient.dart';
import '../models/risk_level.dart';

class DetectionService {
  List<DetectedIngredient> detect({
    required String rawText,
    required List<Ingredient> dictionary,
    required Set<String> selectedAllergens,
  }) {
    final text = normalize(rawText);
    if (text.isEmpty) return const [];

    final results = <DetectedIngredient>[];
    for (final ingredient in dictionary) {
      final keyword = _findKeyword(text, ingredient);
      if (keyword == null) continue;
      results.add(DetectedIngredient(
        ingredientId: ingredient.id,
        ingredientName: ingredient.name,
        matchedKeyword: keyword,
        category: ingredient.category,
        allergenGroup: ingredient.allergenGroup,
        riskLevel: _resolveRisk(ingredient, selectedAllergens),
        description: ingredient.description,
      ));
    }

    results.sort((a, b) {
      final byRisk = a.riskLevel.index.compareTo(b.riskLevel.index);
      return byRisk != 0 ? byRisk : a.ingredientName.compareTo(b.ingredientName);
    });
    return results;
  }

  String normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  String? _findKeyword(String text, Ingredient ingredient) {
    final keywords = ingredient.keywords.map(normalize).where((k) => k.isNotEmpty).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final keyword in keywords) {
      final pattern = RegExp('(?<![a-z0-9])${RegExp.escape(keyword)}(?![a-z0-9])');
      if (pattern.hasMatch(text)) return keyword;
    }
    return null;
  }

  RiskLevel _resolveRisk(Ingredient ingredient, Set<String> selectedAllergens) {
    final group = ingredient.allergenGroup;
    if (group != null && selectedAllergens.contains(group)) return RiskLevel.danger;
    if (ingredient.category.isCautionCategory) return RiskLevel.caution;
    return RiskLevel.safe;
  }
}
