import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/risk_level.dart';
import '../providers/scan_provider.dart';
import '../routes.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<ScanProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pindai Label')),
      body: SafeArea(child: _buildBody(context, scan)),
    );
  }

  Widget _buildBody(BuildContext context, ScanProvider scan) {
    if (scan.isBusy) return LoadingIndicator(message: _busyMessage(scan.status));
    if (scan.status == ScanStatus.error) {
      return EmptyState(
        icon: Icons.image_not_supported_outlined,
        title: 'Pemindaian gagal',
        message: scan.errorMessage,
        actionLabel: 'Coba Lagi',
        onAction: () => context.read<ScanProvider>().reset(),
      );
    }
    return _ScanIdle(onScan: (source) => _startScan(context, source));
  }

  Future<void> _startScan(BuildContext context, ScanSource source) async {
    final navigator = Navigator.of(context);
    final result = await context.read<ScanProvider>().scan(source);
    if (result != null) navigator.pushNamed(AppRoutes.scanResult, arguments: result);
  }

  String _busyMessage(ScanStatus status) => switch (status) {
        ScanStatus.pickingImage => 'Membuka kamera...',
        ScanStatus.recognizing => 'Membaca teks pada label...',
        _ => 'Mencocokkan dengan kamus bahan...',
      };
}

class _ScanIdle extends StatelessWidget {
  const _ScanIdle({required this.onScan});

  final ValueChanged<ScanSource> onScan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: scheme.outlineVariant, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 72, color: scheme.primary),
                  const SizedBox(height: 16),
                  Text('Arahkan ke daftar komposisi', style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Pastikan teks terang, lurus, dan tidak buram agar terbaca lebih dari 80%.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => onScan(ScanSource.camera),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Ambil Foto'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => onScan(ScanSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Pilih dari Galeri'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
    );
  }
}
