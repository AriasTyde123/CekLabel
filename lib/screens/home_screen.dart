import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/risk_level.dart';
import '../providers/dictionary_provider.dart';
import '../providers/preference_provider.dart';
import '../providers/scan_provider.dart';
import '../routes.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/risk_badge.dart';
import '../widgets/summary_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dictionary = context.watch<DictionaryProvider>();
    final preference = context.watch<PreferenceProvider>();
    final scan = context.watch<ScanProvider>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (dictionary.status == DictionaryStatus.loading || dictionary.status == DictionaryStatus.initial) {
      return const Scaffold(body: LoadingIndicator(message: 'Memuat kamus bahan...'));
    }
    if (dictionary.status == DictionaryStatus.error) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.error_outline,
          title: dictionary.errorMessage ?? 'Gagal memuat kamus bahan.',
          actionLabel: 'Coba Lagi',
          onAction: () => context.read<DictionaryProvider>().load(),
        ),
      );
    }

    final lastResult = scan.result;
    final lastSummary = lastResult == null ? null : scan.summarize(lastResult);
    final greeting = preference.savedUserName.isEmpty ? 'Halo!' : 'Halo, ${preference.savedUserName}!';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.document_scanner_rounded, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Text('CekLabel', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 28),
            Text(greeting, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Foto label komposisi makanan, dan kami terjemahkan istilah rumitnya dalam hitungan detik. '
              'Semua diproses di perangkatmu, tanpa internet.',
              style: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    icon: Icons.menu_book_rounded,
                    value: '${dictionary.ingredients.length}',
                    label: 'Bahan di kamus',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    icon: Icons.shield_outlined,
                    value: '${preference.savedAllergens.length}',
                    label: 'Alergen diwaspadai',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LastScanCard(
              message: lastSummary?.message,
              level: lastSummary?.overallLevel,
              total: lastSummary?.totalDetected,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.scan),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Pindai Label'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.dictionary),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Cari Bahan'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.preferences),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Atur Preferensi'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LastScanCard extends StatelessWidget {
  const _LastScanCard({required this.message, required this.level, required this.total});

  final String? message;
  final RiskLevel? level;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasScan = message != null;
    final color = hasScan ? RiskStyle.color(level!) : scheme.outline;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(hasScan ? RiskStyle.icon(level!) : Icons.history_rounded, color: color, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pindaian terakhir', style: textTheme.labelMedium?.copyWith(color: scheme.outline)),
                  const SizedBox(height: 2),
                  Text(
                    hasScan ? message! : 'Belum ada pindaian',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (hasScan) Text('$total bahan dikenali', style: textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
