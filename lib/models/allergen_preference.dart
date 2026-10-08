const List<String> availableAllergens = ['Kacang', 'Susu', 'Gluten', 'Telur', 'Udang', 'Kedelai'];

class AllergenPreference {
  const AllergenPreference({this.userName = '', this.selectedAllergens = const {}});

  final String userName;
  final Set<String> selectedAllergens;

  AllergenPreference copyWith({String? userName, Set<String>? selectedAllergens}) {
    return AllergenPreference(
      userName: userName ?? this.userName,
      selectedAllergens: selectedAllergens ?? this.selectedAllergens,
    );
  }
}
