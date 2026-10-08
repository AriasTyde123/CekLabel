import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/risk_level.dart';
import '../models/scan_result.dart';
import '../providers/scan_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/ingredient_card.dart';
import '../widgets/warning_banner.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key, required this.result});

  final ScanResult? result;

  @override
  Widget build(BuildContext context) {
    final data = result;
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hasil Pindaian')),
        body: const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'Belum ada hasil pindaian',
          message: 'Pindai label komposisi terlebih dahulu.',
        ),
      );
    }

    final summary = context.read<ScanProvider>().summarize(data);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Pindaian')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            WarningBanner(level: summary.overallLevel, title: _bannerTitle(summary), message: summary.message),
            const SizedBox(height: 24),
            Text('Bahan terdeteksi (${summary.totalDetected})',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (data.detectedIngredients.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Tidak ada bahan dikenali',
                  message: 'Coba foto ulang dengan pencahayaan lebih baik.',
                ),
              )
            else
              for (final item in data.detectedIngredients)
                IngredientCard(
                  name: item.ingredientName,
                  matchedKeyword: item.matchedKeyword,
                  category: item.category,
                  riskLevel: item.riskLevel,
                  description: item.description,
                ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: ExpansionTile(
                title: const Text('Lihat Teks Asli'),
                shape: const Border(),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedAlignment: Alignment.centerLeft,
                children: [SelectableText(data.rawText, style: textTheme.bodySmall)],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Pindai Lagi'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            ),
          ],
        ),
      ),
    );
  }

  String _bannerTitle(ScanSummary summary) => switch (summary.overallLevel) {
        RiskLevel.danger => summary.allergenGroups.isEmpty
            ? 'Awas! Mengandung Alergen'
            : 'Awas! Mengandung ${summary.allergenGroups.join(', ')}',
        RiskLevel.caution => 'Kemungkinan Mengandung Gula Tersembunyi',
        RiskLevel.safe => 'Aman',
      };
}
