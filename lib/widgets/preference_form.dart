import 'package:flutter/material.dart';

import '../models/allergen_preference.dart';
import 'allergen_checkbox.dart';

class PreferenceForm extends StatelessWidget {
  const PreferenceForm({
    super.key,
    required this.nameController,
    required this.selectedAllergens,
    required this.nameError,
    required this.allergenError,
    required this.onNameChanged,
    required this.onAllergenToggled,
  });

  final TextEditingController nameController;
  final Set<String> selectedAllergens;
  final String? nameError;
  final String? allergenError;
  final ValueChanged<String> onNameChanged;
  final void Function(String allergen, bool selected) onAllergenToggled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          onChanged: onNameChanged,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Nama panggilan',
            prefixIcon: const Icon(Icons.person_outline),
            errorText: nameError,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Text('Alergen yang diwaspadai', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Bahan yang cocok akan ditandai merah saat pemindaian.',
            style: textTheme.bodySmall?.copyWith(color: scheme.outline)),
        const SizedBox(height: 12),
        for (final allergen in availableAllergens)
          AllergenCheckbox(
            label: allergen,
            value: selectedAllergens.contains(allergen),
            onChanged: (selected) => onAllergenToggled(allergen, selected),
          ),
        if (allergenError != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(allergenError!, style: textTheme.bodySmall?.copyWith(color: scheme.error)),
          ),
      ],
    );
  }
}
