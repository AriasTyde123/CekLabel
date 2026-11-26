import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/risk_level.dart';
import '../providers/scan_provider.dart';
import '../routes.dart';
import '../widgets/empty_state.dart';
import '../widgets/home_scan_rows.dart';

class ScanCollectionScreen extends StatelessWidget {
  const ScanCollectionScreen({super.key, this.safeOnly = false, this.embedded = false});

  final bool safeOnly;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<ScanProvider>();
    final rows = [
      for (final result in scan.history)
        HomeScanRow.result(
          result,
          context: context,
          risk: scan.summarize(result).overallLevel,
          onTap: () => Navigator.pushNamed(context, AppRoutes.scanResult, arguments: result),
        ),
    ];
    final visible = safeOnly ? rows.where((row) => row.risk == RiskLevel.safe).toList() : rows;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !embedded,
        title: Text(safeOnly ? 'Daftar Aman' : 'Riwayat Pindaian'),
      ),
      body: SafeArea(
        bottom: !embedded,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (safeOnly) ...[
              Card(
                color: scheme.primaryContainer,
                margin: EdgeInsets.zero,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Daftar ini berdasarkan preferensi saat label dipindai. '
                    'Selalu periksa label asli; hasil pindai bukan jaminan produk bebas alergen.',
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (visible.isEmpty)
              EmptyState(
                icon: safeOnly ? Icons.bookmark_border_rounded : Icons.history_rounded,
                title: safeOnly ? 'Belum ada hasil berisiko rendah' : 'Belum ada pindaian',
                message: 'Pindai label makanan untuk menambahkan hasil ke sesi ini.',
              )
            else
              HomeScanRows(rows: visible),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.scan),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Pindai Label'),
            ),
            if (safeOnly)
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.dictionary),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Buka Kamus Bahan'),
              ),
          ],
        ),
      ),
    );
  }
}
