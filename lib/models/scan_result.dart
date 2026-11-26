import 'cross_contamination.dart';
import 'detected_ingredient.dart';
import 'profile_impact.dart';
import 'risk_level.dart';

const String defaultProductName = 'Produk tanpa nama';

class ScanResult {
  const ScanResult({
    required this.id,
    required this.rawText,
    required this.detectedIngredients,
    required this.dangerCount,
    required this.cautionCount,
    required this.safeCount,
    required this.scannedAt,
    required this.createdAt,
    this.productName = defaultProductName,
    this.brand = '',
    this.crossContamination,
    this.isSaved = false,
  });

  factory ScanResult.create({
    required String rawText,
    required List<DetectedIngredient> detected,
    String productName = defaultProductName,
    CrossContamination? crossContamination,
  }) {
    final now = DateTime.now();
    int count(RiskLevel level) => detected.where((item) => item.riskLevel == level).length;
    return ScanResult(
      id: now.microsecondsSinceEpoch.toString(),
      rawText: rawText,
      detectedIngredients: List.unmodifiable(detected),
      dangerCount: count(RiskLevel.danger),
      cautionCount: count(RiskLevel.caution),
      safeCount: count(RiskLevel.safe),
      scannedAt: now,
      createdAt: now,
      productName: productName,
      crossContamination: crossContamination,
    );
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final cross = json['crossContamination'];
    final name = (json['productName'] as String?)?.trim() ?? '';
    return ScanResult(
      id: json['id'] as String,
      rawText: json['rawText'] as String? ?? '',
      detectedIngredients: List.unmodifiable([
        for (final item in json['detectedIngredients'] as List? ?? const [])
          DetectedIngredient.fromJson(Map<String, dynamic>.from(item as Map)),
      ]),
      dangerCount: json['dangerCount'] as int? ?? 0,
      cautionCount: json['cautionCount'] as int? ?? 0,
      safeCount: json['safeCount'] as int? ?? 0,
      scannedAt: DateTime.parse(json['scannedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      productName: name.isEmpty ? defaultProductName : name,
      brand: json['brand'] as String? ?? '',
      crossContamination: cross is Map ? CrossContamination.fromJson(Map<String, dynamic>.from(cross)) : null,
      isSaved: json['isSaved'] as bool? ?? false,
    );
  }

  final String id;
  final String rawText;
  final List<DetectedIngredient> detectedIngredients;
  final int dangerCount;
  final int cautionCount;
  final int safeCount;
  final DateTime scannedAt;
  final DateTime createdAt;
  final String productName;
  final String brand;
  final CrossContamination? crossContamination;
  final bool isSaved;

  int get totalDetected => detectedIngredients.length;

  ScanResult copyWith({String? productName, String? brand, bool? isSaved}) => ScanResult(
        id: id,
        rawText: rawText,
        detectedIngredients: detectedIngredients,
        dangerCount: dangerCount,
        cautionCount: cautionCount,
        safeCount: safeCount,
        scannedAt: scannedAt,
        createdAt: createdAt,
        productName: productName ?? this.productName,
        brand: brand ?? this.brand,
        crossContamination: crossContamination,
        isSaved: isSaved ?? this.isSaved,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'rawText': rawText,
        'detectedIngredients': [for (final item in detectedIngredients) item.toJson()],
        'dangerCount': dangerCount,
        'cautionCount': cautionCount,
        'safeCount': safeCount,
        'scannedAt': scannedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'productName': productName,
        'brand': brand,
        'crossContamination': crossContamination?.toJson(),
        'isSaved': isSaved,
      };
}

/// Live evaluation of a [ScanResult] against the currently active family profiles.
class ScanSummary {
  const ScanSummary({
    required this.totalDetected,
    required this.dangerCount,
    required this.cautionCount,
    required this.hasUserAllergen,
    required this.topRisks,
    required this.allergenGroups,
    required this.message,
    required this.overallLevel,
    required this.subtitle,
    required this.ingredients,
    required this.impacts,
    required this.crossContamination,
    required this.hasHiddenSugar,
    required this.hasAdditives,
  });

  final int totalDetected;
  final int dangerCount;
  final int cautionCount;
  final bool hasUserAllergen;
  final List<DetectedIngredient> topRisks;

  /// Allergen groups that directly match an active profile.
  final List<String> allergenGroups;
  final String message;
  final RiskLevel overallLevel;

  /// Short explanation under the traffic light headline.
  final String subtitle;

  /// Ingredients re-evaluated against the active profiles, most severe first.
  final List<DetectedIngredient> ingredients;
  final List<ProfileImpact> impacts;
  final CrossContamination? crossContamination;
  final bool hasHiddenSugar;
  final bool hasAdditives;

  String get headline => overallLevel.headline;
}
