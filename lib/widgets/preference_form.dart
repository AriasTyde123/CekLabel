import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/allergen_preference.dart';
import '../providers/preference_provider.dart';
import '../providers/preference_status.dart';
import 'allergen_checkbox.dart';

class PreferenceForm extends StatefulWidget {
  const PreferenceForm({super.key});

  @override
  State<PreferenceForm> createState() => _PreferenceFormState();
}

class _PreferenceFormState extends State<PreferenceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: context.read<PreferenceProvider>().preference.userName,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userName = context.watch<PreferenceProvider>().preference.userName;
    if (_nameController.text != userName) {
      _nameController.text = userName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit(PreferenceProvider provider) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    final allergenError = provider.validateAllergens();
    if (!isValid || allergenError != null) {
      if (allergenError != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(allergenError)),
        );
      }
      setState(() {});
      return;
    }
    final success = await provider.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Preferensi tersimpan' : provider.errorMessage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PreferenceProvider>();
    final isSaving = provider.status == PreferenceStatus.saving;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama pengguna',
              border: OutlineInputBorder(),
            ),
            onChanged: provider.updateUserName,
            validator: provider.validateUserName,
          ),
          const SizedBox(height: 16),
          const Text(
            'Pilih alergen yang diwaspadai',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final allergen in AllergenPreference.availableAllergens)
            AllergenCheckbox(
              label: allergen,
              value: provider.preference.selectedAllergens.contains(allergen),
              onChanged: (_) => provider.toggleAllergen(allergen),
            ),
          if (provider.validateAllergens() != null &&
              provider.preference.selectedAllergens.isNotEmpty == false)
            const Text(
              'Pilih minimal 1 alergen',
              style: TextStyle(color: Colors.red),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isSaving ? null : () => _submit(provider),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan Preferensi'),
          ),
        ],
      ),
    );
  }
}
