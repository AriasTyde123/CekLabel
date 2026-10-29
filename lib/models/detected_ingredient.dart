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

  Map<String, dynamic> toJson() => {
        'ingredientId': ingredientId,
        'ingredientName': ingredientName,
        'matchedKeyword': matchedKeyword,
        'category': category.name,
        'allergenGroup': allergenGroup,
        'riskLevel': riskLevel.name,
        'description': description,
      };

  factory DetectedIngredient.fromJson(Map<String, dynamic> json) {
    return DetectedIngredient(
      ingredientId: json['ingredientId'] as String,
      ingredientName: json['ingredientName'] as String,
      matchedKeyword: json['matchedKeyword'] as String,
      category: IngredientCategory.values.asNameMap()[json['category']] ?? IngredientCategory.other,
      allergenGroup: json['allergenGroup'] as String?,
      riskLevel: RiskLevel.values.asNameMap()[json['riskLevel']] ?? RiskLevel.safe,
      description: json['description'] as String,
    );
  }
}
