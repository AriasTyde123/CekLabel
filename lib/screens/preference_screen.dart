import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/preference_provider.dart';
import '../providers/preference_status.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/preference_form.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: context.read<PreferenceProvider>().userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<PreferenceProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final saved = await provider.save();
    if (saved) {
      messenger.showSnackBar(const SnackBar(content: Text('Preferensi tersimpan')));
    } else if (provider.status == PreferenceStatus.error) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Gagal menyimpan preferensi. Coba lagi.')),
      );
    }
  }

  Future<void> _confirmReset() async {
    final provider = context.read<PreferenceProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atur ulang preferensi?'),
        content: const Text('Nama dan daftar alergen yang tersimpan akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Atur Ulang')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (await provider.reset()) _nameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PreferenceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Atur Preferensi')),
      body: SafeArea(
        child: provider.status == PreferenceStatus.loading
            ? const LoadingIndicator()
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  PreferenceForm(
                    nameController: _nameController,
                    selectedAllergens: provider.selectedAllergens,
                    nameError: provider.nameError,
                    allergenError: provider.allergenError,
                    onNameChanged: provider.setUserName,
                    onAllergenToggled: provider.toggleAllergen,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: provider.isBusy ? null : _save,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                    child: provider.status == PreferenceStatus.saving
                        ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : const Text('Simpan'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(onPressed: provider.isBusy ? null : _confirmReset, child: const Text('Atur Ulang')),
                ],
              ),
      ),
    );
  }
}
