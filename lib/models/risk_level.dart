enum RiskLevel { danger, caution, safe }

enum ScanStatus { initial, pickingImage, recognizing, analyzing, success, error }

enum ScanSource { camera, gallery }

extension RiskLevelLabel on RiskLevel {
  String get label => switch (this) {
        RiskLevel.danger => 'Bahaya',
        RiskLevel.caution => 'Waspada',
        RiskLevel.safe => 'Aman',
      };
}
