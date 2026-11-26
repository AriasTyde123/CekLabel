import 'family_profile.dart';
import 'risk_level.dart';

class ProfileImpact {
  const ProfileImpact({required this.profile, required this.level, required this.reasons});

  final FamilyProfile profile;
  final RiskLevel level;
  final List<String> reasons;

  /// e.g. "Bahaya (Susu & Kacang)" or "Aman".
  String get label => reasons.isEmpty ? level.label : '${level.label} (${reasons.join(' & ')})';
}

