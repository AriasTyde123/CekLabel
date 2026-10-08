import 'risk_level.dart';

enum IngredientCategory { sugarAlias, allergen, additive, preservative, coloring, sweetener, other }

extension IngredientCategoryLabel on IngredientCategory {
  String get label => switch (this) {
        IngredientCategory.sugarAlias => 'Gula Tersembunyi',
        IngredientCategory.allergen => 'Alergen',
        IngredientCategory.additive => 'Zat Aditif',
        IngredientCategory.preservative => 'Pengawet',
        IngredientCategory.coloring => 'Pewarna',
        IngredientCategory.sweetener => 'Pemanis',
        IngredientCategory.other => 'Lainnya',
      };

  bool get isCautionCategory =>
      this == IngredientCategory.sugarAlias ||
      this == IngredientCategory.additive ||
      this == IngredientCategory.preservative ||
      this == IngredientCategory.coloring;
}

class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.aliases,
    required this.category,
    required this.allergenGroup,
    required this.description,
    required this.riskLevelDefault,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      name: json['name'] as String,
      aliases: List<String>.from(json['aliases'] as List? ?? const []),
      category: IngredientCategory.values.asNameMap()[json['category']] ?? IngredientCategory.other,
      allergenGroup: json['allergenGroup'] as String?,
      description: json['description'] as String,
      riskLevelDefault: RiskLevel.values.asNameMap()[json['riskLevelDefault']] ?? RiskLevel.safe,
    );
  }

  final String id;
  final String name;
  final List<String> aliases;
  final IngredientCategory category;
  final String? allergenGroup;
  final String description;
  final RiskLevel riskLevelDefault;

  List<String> get keywords => [name, ...aliases];
}
