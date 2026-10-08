import 'ingredient.dart';
import 'risk_level.dart';

class DetectedIngredient {
  const DetectedIngredient({
    required this.ingredientId,
    required this.ingredientName,
    required this.matchedKeyword,
    required this.category,
    required this.allergenGroup,
    required this.riskLevel,
    required this.description,
  });

  final String ingredientId;
  final String ingredientName;
  final String matchedKeyword;
  final IngredientCategory category;
  final String? allergenGroup;
  final RiskLevel riskLevel;
  final String description;
}
