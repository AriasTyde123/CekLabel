class AllergenPreference {
  const AllergenPreference({
    required this.userName,
    required this.selectedAllergens,
  });

  final String userName;
  final Set<String> selectedAllergens;

  static const List<String> availableAllergens = [
    'Kacang',
    'Susu',
    'Gluten',
    'Telur',
    'Udang',
    'Kedelai',
  ];

  AllergenPreference copyWith({
    String? userName,
    Set<String>? selectedAllergens,
  }) {
    return AllergenPreference(
      userName: userName ?? this.userName,
      selectedAllergens: selectedAllergens ?? this.selectedAllergens,
    );
  }
}
