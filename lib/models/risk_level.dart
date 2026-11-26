enum RiskLevel { danger, caution, safe }

enum ScanStatus { initial, pickingImage, recognizing, analyzing, success, error }

enum ScanSource { camera, gallery }

extension RiskLevelLabel on RiskLevel {
  String get label => switch (this) {
        RiskLevel.danger => 'Bahaya',
        RiskLevel.caution => 'Waspada',
        RiskLevel.safe => 'Aman',
      };

  /// Banner headline for the traffic light system.
  String get headline => switch (this) {
        RiskLevel.danger => 'TIDAK AMAN',
        RiskLevel.caution => 'WASPADA',
        RiskLevel.safe => 'AMAN',
      };
}

/// Returns the most severe level, or [RiskLevel.safe] when empty.
RiskLevel worstRisk(Iterable<RiskLevel> levels) {
  var worst = RiskLevel.safe;
  for (final level in levels) {
    if (level.index < worst.index) worst = level;
  }
  return worst;
}
