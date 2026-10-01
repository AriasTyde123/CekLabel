import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/preference_provider.dart';
import '../providers/preference_status.dart';
import '../widgets/preference_form.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PreferenceProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PreferenceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Preferensi Alergen')),
      body: switch (provider.status) {
        PreferenceStatus.initial => const Center(
            child: Text('Belum ada data preferensi'),
          ),
        PreferenceStatus.loading || PreferenceStatus.saving =>
          const Center(child: CircularProgressIndicator()),
        PreferenceStatus.error => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(provider.errorMessage),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: provider.load,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        PreferenceStatus.loaded ||
        PreferenceStatus.success =>
          const PreferenceForm(),
      },
    );
  }
}
