const List<String> availableAllergens = ['Kacang', 'Susu', 'Gluten', 'Telur', 'Udang', 'Kedelai'];

const List<String> profileRoles = ['Saya', 'Anak', 'Ayah', 'Ibu', 'Kakek', 'Nenek', 'Lainnya'];

enum SensitivityLevel { mild, severe }

extension SensitivityLevelLabel on SensitivityLevel {
  String get label => switch (this) {
        SensitivityLevel.mild => 'Intoleransi Ringan',
        SensitivityLevel.severe => 'Alergi Berat / Anafilaksis',
      };
}

class FamilyProfile {
  const FamilyProfile({
    required this.id,
    required this.name,
    this.role = 'Saya',
    this.allergens = const {},
    this.sensitivity = SensitivityLevel.mild,
    this.avoidHiddenSugar = false,
    this.avoidAdditives = false,
    this.isActive = true,
  });

  factory FamilyProfile.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String?;
    return FamilyProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      role: profileRoles.contains(role) ? role! : 'Lainnya',
      allergens: List<String>.from(json['allergens'] as List? ?? const [])
          .where(availableAllergens.contains)
          .toSet(),
      sensitivity: SensitivityLevel.values.asNameMap()[json['sensitivity']] ?? SensitivityLevel.mild,
      avoidHiddenSugar: json['avoidHiddenSugar'] as bool? ?? false,
      avoidAdditives: json['avoidAdditives'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  final String id;
  final String name;
  final String role;
  final Set<String> allergens;
  final SensitivityLevel sensitivity;
  final bool avoidHiddenSugar;
  final bool avoidAdditives;
  final bool isActive;

  bool get isSevere => sensitivity == SensitivityLevel.severe;

  bool get hasAnyFilter => allergens.isNotEmpty || avoidHiddenSugar || avoidAdditives;

  /// Allergens in the canonical display order.
  List<String> get orderedAllergens => [for (final item in availableAllergens) if (allergens.contains(item)) item];

  String get summary {
    final parts = [
      if (allergens.isNotEmpty) 'Alergi ${orderedAllergens.join(', ')}',
      if (avoidHiddenSugar) 'Rendah Gula',
      if (avoidAdditives) 'Tanpa Aditif',
    ];
    return parts.isEmpty ? 'Belum ada filter' : parts.join(' · ');
  }

  FamilyProfile copyWith({
    String? name,
    String? role,
    Set<String>? allergens,
    SensitivityLevel? sensitivity,
    bool? avoidHiddenSugar,
    bool? avoidAdditives,
    bool? isActive,
  }) {
    return FamilyProfile(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      allergens: allergens ?? this.allergens,
      sensitivity: sensitivity ?? this.sensitivity,
      avoidHiddenSugar: avoidHiddenSugar ?? this.avoidHiddenSugar,
      avoidAdditives: avoidAdditives ?? this.avoidAdditives,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'allergens': orderedAllergens,
        'sensitivity': sensitivity.name,
        'avoidHiddenSugar': avoidHiddenSugar,
        'avoidAdditives': avoidAdditives,
        'isActive': isActive,
      };
}

