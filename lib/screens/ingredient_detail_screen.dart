import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dictionary_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/risk_badge.dart';

class IngredientDetailScreen extends StatelessWidget {
  const IngredientDetailScreen({super.key, required this.ingredientId});

  final String? ingredientId;

  @override
  Widget build(BuildContext context) {
    final id = ingredientId;
    final ingredient = id == null ? null : context.watch<DictionaryProvider>().findById(id);

    if (ingredient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Bahan')),
        body: const EmptyState(icon: Icons.help_outline_rounded, title: 'Bahan tidak ditemukan'),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Bahan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(ingredient.name, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                RiskBadge(level: ingredient.riskLevelDefault),
                CategoryBadge(category: ingredient.category),
                if (ingredient.allergenGroup != null)
                  Chip(label: Text('Alergen ${ingredient.allergenGroup}'), visualDensity: VisualDensity.compact),
              ],
            ),
            const SizedBox(height: 24),
            Text('Artinya dalam bahasa awam', style: textTheme.titleSmall?.copyWith(color: scheme.outline)),
            const SizedBox(height: 6),
            Text(ingredient.description, style: textTheme.bodyLarge),
            if (ingredient.aliases.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Nama lain di label', style: textTheme.titleSmall?.copyWith(color: scheme.outline)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final alias in ingredient.aliases) Chip(label: Text(alias))],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
