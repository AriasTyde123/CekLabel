import 'detected_ingredient.dart';
import 'risk_level.dart';

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
  });

  factory ScanResult.create({required String rawText, required List<DetectedIngredient> detected}) {
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

  int get totalDetected => detectedIngredients.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'rawText': rawText,
        'detectedIngredients': detectedIngredients.map((item) => item.toJson()).toList(),
        'dangerCount': dangerCount,
        'cautionCount': cautionCount,
        'safeCount': safeCount,
        'scannedAt': scannedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'] as String,
      rawText: json['rawText'] as String,
      detectedIngredients: List.unmodifiable(
        (json['detectedIngredients'] as List? ?? const [])
            .map((item) => DetectedIngredient.fromJson(item as Map<String, dynamic>)),
      ),
      dangerCount: json['dangerCount'] as int? ?? 0,
      cautionCount: json['cautionCount'] as int? ?? 0,
      safeCount: json['safeCount'] as int? ?? 0,
      scannedAt: DateTime.tryParse(json['scannedAt'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ScanSummary {
  const ScanSummary({
    required this.totalDetected,
    required this.dangerCount,
    required this.cautionCount,
    required this.hasUserAllergen,
    required this.topRisks,
    required this.allergenGroups,
    required this.message,
  });

  final int totalDetected;
  final int dangerCount;
  final int cautionCount;
  final bool hasUserAllergen;
  final List<DetectedIngredient> topRisks;
  final List<String> allergenGroups;
  final String message;

  RiskLevel get overallLevel {
    if (dangerCount > 0) return RiskLevel.danger;
    if (cautionCount > 0) return RiskLevel.caution;
    return RiskLevel.safe;
  }
}
