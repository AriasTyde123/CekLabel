import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dictionary_provider.dart';
import '../routes.dart';
import '../widgets/empty_state.dart';
import '../widgets/ingredient_card.dart';
import '../widgets/loading_indicator.dart';

class DictionaryScreen extends StatelessWidget {
  const DictionaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dictionary = context.watch<DictionaryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cari Bahan')),
      body: SafeArea(child: _buildBody(context, dictionary)),
    );
  }

  Widget _buildBody(BuildContext context, DictionaryProvider dictionary) {
    if (dictionary.status == DictionaryStatus.loading) return const LoadingIndicator();
    if (dictionary.status == DictionaryStatus.error) {
      return EmptyState(
        icon: Icons.error_outline,
        title: dictionary.errorMessage ?? 'Gagal memuat kamus bahan.',
        actionLabel: 'Coba Lagi',
        onAction: () => context.read<DictionaryProvider>().load(),
      );
    }

    final items = dictionary.filtered;
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
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 20, 8),
            child: Text('${items.length} bahan', style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Tidak ditemukan. Coba kata kunci lain.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return IngredientCard(
                      name: item.name,
                      category: item.category,
                      riskLevel: item.riskLevelDefault,
                      description: item.description,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.dictionaryDetail, arguments: item.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
