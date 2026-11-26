class CrossContamination {
  const CrossContamination({required this.allergenGroups, required this.statement});

  factory CrossContamination.fromJson(Map<String, dynamic> json) => CrossContamination(
        allergenGroups: List<String>.from(json['allergenGroups'] as List? ?? const []),
        statement: json['statement'] as String? ?? '',
      );

  /// Allergen groups mentioned in "may contain" / shared facility statements.
  final List<String> allergenGroups;

  /// The warning sentence as found on the label.
  final String statement;

  Map<String, dynamic> toJson() => {'allergenGroups': allergenGroups, 'statement': statement};
}

