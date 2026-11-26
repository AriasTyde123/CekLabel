import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
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
    context.watch<ProfileProvider>();
    final source = safeOnly ? scan.savedResults : scan.history;
    final rows = [
      for (final result in source)
        HomeScanRow.result(
          result,
          context: context,
          risk: scan.summarize(result).overallLevel,
          onTap: () => Navigator.pushNamed(context, AppRoutes.scanResult, arguments: result),
        ),
    ];
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
                    'Produk yang Anda tandai dengan ikon bookmark tersimpan di sini secara lokal. '
                    'Selalu periksa ulang label kemasan karena komposisi produsen dapat berubah.',
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (rows.isEmpty)
              EmptyState(
                icon: safeOnly ? Icons.bookmark_border_rounded : Icons.history_rounded,
                title: safeOnly ? 'Belum ada produk di Daftar Aman' : 'Belum ada pindaian',
                message: safeOnly
                    ? 'Ketuk ikon bookmark di halaman hasil pindaian untuk menyimpan produk favorit Anda.'
                    : 'Pindai label makanan untuk menambahkan hasil ke riwayat perangkat ini.',
              )
            else
              HomeScanRows(rows: rows),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.scan),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Pindai Label'),
            ),
            if (safeOnly) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.dictionary),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Buka Kamus Bahan'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
