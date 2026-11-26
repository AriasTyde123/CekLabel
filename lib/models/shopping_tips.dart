import 'risk_level.dart';
import 'scan_result.dart';

class ShoppingTips {
  const ShoppingTips({required this.tips, required this.isOffline});

  final List<String> tips;

  /// True when tips come from the local fallback instead of Gemini AI.
  final bool isOffline;
}

class TipRequest {
  const TipRequest({
    required this.resultId,
    required this.productName,
    required this.overallLevel,
    required this.allergenGroups,
    required this.crossContaminationGroups,
    required this.hasHiddenSugar,
    required this.hasAdditives,
    required this.riskyIngredients,
    this.hasSyubhat = false,
  });

  factory TipRequest.fromSummary(ScanResult result, ScanSummary summary) => TipRequest(
        resultId: result.id,
        productName: result.productName,
        overallLevel: summary.overallLevel,
        allergenGroups: summary.allergenGroups,
        crossContaminationGroups: summary.crossContamination?.allergenGroups ?? const [],
        hasHiddenSugar: summary.hasHiddenSugar,
        hasAdditives: summary.hasAdditives,
        hasSyubhat: summary.hasSyubhat || summary.hasNonHalal,
        riskyIngredients: [
          for (final item in summary.ingredients)
            if (item.riskLevel != RiskLevel.safe) item.ingredientName,
        ],
      );

  final String resultId;
  final String productName;
  final RiskLevel overallLevel;
  final List<String> allergenGroups;
  final List<String> crossContaminationGroups;
  final bool hasHiddenSugar;
  final bool hasAdditives;
  final bool hasSyubhat;
  final List<String> riskyIngredients;

  /// Changes whenever the evaluation input changes (e.g. profiles toggled).
  String get cacheKey => [
        resultId,
        overallLevel.name,
        allergenGroups.join(','),
        crossContaminationGroups.join(','),
        hasHiddenSugar,
        hasAdditives,
        hasSyubhat,
        riskyIngredients.join(','),
      ].join('|');
}
