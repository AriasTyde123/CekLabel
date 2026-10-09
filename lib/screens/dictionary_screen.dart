import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/risk_level.dart';
import '../providers/dictionary_provider.dart';
import '../providers/preference_provider.dart';
import '../routes.dart';
import '../widgets/empty_state.dart';
import '../widgets/ingredient_card.dart';
import '../widgets/loading_indicator.dart';

class DictionaryScreen extends StatelessWidget {
  const DictionaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dictionary = context.watch<DictionaryProvider>();
    final preference = context.watch<PreferenceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cari Bahan')),
      body: SafeArea(child: _buildBody(context, dictionary, preference)),
    );
  }

  Widget _buildBody(BuildContext context, DictionaryProvider dictionary, PreferenceProvider preference) {
    if (dictionary.status == DictionaryStatus.loading) return const LoadingIndicator();
    if (dictionary.status == DictionaryStatus.error) {
      return EmptyState(
        icon: Icons.error_outline,
        title: dictionary.errorMessage ?? 'Gagal memuat kamus bahan.',
        actionLabel: 'Coba Lagi',
        onAction: () => context.read<DictionaryProvider>().load(),
      );
    }

    final savedAllergens = preference.savedAllergens;
    final items = dictionary.filtered(savedAllergens);
    final onlyAllergens = dictionary.onlyUserAllergens;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: SearchBar(
            hintText: 'Cari bahan... (maltodekstrin, tartrazin, E621)',
            leading: const Icon(Icons.search_rounded),
            elevation: const WidgetStatePropertyAll(0),
            onChanged: context.read<DictionaryProvider>().setQuery,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              FilterChip(
                label: Text(
                  onlyAllergens && savedAllergens.isNotEmpty
                      ? 'Alergen Saya (${items.length})'
                      : 'Alergen Saya',
                ),
                selected: onlyAllergens,
                onSelected: (selected) {
                  context.read<DictionaryProvider>().toggleOnlyUserAllergens(selected);
                },
              ),
              const Spacer(),
              Text('${items.length} bahan', style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: onlyAllergens && savedAllergens.isEmpty
              ? EmptyState(
                  icon: Icons.shield_outlined,
                  title: 'Belum ada alergen yang dipilih',
                  message: 'Atur preferensi alergen Anda terlebih dahulu agar dapat difilter.',
                  actionLabel: 'Atur Preferensi',
                  onAction: () => Navigator.pushNamed(context, AppRoutes.preferences),
                )
              : items.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Tidak ditemukan. Coba kata kunci lain.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isUserAllergen = item.allergenGroup != null && savedAllergens.contains(item.allergenGroup);
                        final displayRisk = isUserAllergen ? RiskLevel.danger : item.riskLevelDefault;

                        return IngredientCard(
                          name: item.name,
                          category: item.category,
                          riskLevel: displayRisk,
                          description: item.description,
                          userAllergenGroup: isUserAllergen ? item.allergenGroup : null,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.dictionaryDetail, arguments: item.id),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
