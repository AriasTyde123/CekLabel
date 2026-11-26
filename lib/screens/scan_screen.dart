import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/risk_level.dart';
import '../providers/profile_provider.dart';
import '../providers/scan_provider.dart';
import '../routes.dart';
import '../widgets/scanner_view.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _barcode = false;
  bool _flash = false;

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<ScanProvider>();
    final activeProfiles = context.watch<ProfileProvider>().activeProfiles;
    final profileNames = activeProfiles.map((p) => p.name).join(', ');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF091813),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF091813),
        body: ScannerView(
          barcode: _barcode,
          flash: _flash,
          busy: scan.isBusy,
          hasProfile: activeProfiles.isNotEmpty,
          hint: scan.isBusy
              ? _busyMessage(scan.status)
              : _barcode
                  ? 'Arahkan kamera ke barcode di kemasan'
                  : 'Arahkan kamera ke daftar komposisi di kemasan',
          error: !_barcode && scan.status == ScanStatus.error ? scan.errorMessage : null,
          onClose: () => Navigator.maybePop(context),
          onMode: (barcode) => setState(() => _barcode = barcode),
          onFlash: () => setState(() => _flash = !_flash),
          onHelp: () => _showInfo(
            icon: Icons.help_outline_rounded,
            title: 'Cara memindai label',
            message: 'Ratakan kemasan, hindari pantulan cahaya, dan pastikan teks komposisi terlihat jelas. '
                'Bingkai dan lampu kilat di layar ini adalah simulasi. Ketuk tombol foto untuk membuka kamera perangkat.',
          ),
          onGallery: () => _startScan(ScanSource.gallery),
          onCapture: () => _startScan(ScanSource.camera),
          onProfiles: () => _showInfo(
            icon: Icons.group_outlined,
            title: 'Profil yang dicek',
            message: activeProfiles.isEmpty
                ? 'Belum ada profil aktif. Tambahkan profil di tab Profil untuk memakai preferensi alergen keluarga Anda.'
                : 'Pemindaian memakai preferensi dari ${activeProfiles.length} profil aktif: $profileNames.',
          ),
          onRetry: scan.reset,
        ),
      ),
    );
  }

  Future<void> _startScan(ScanSource source) async {
    if (_barcode) {
      await _showInfo(
        icon: Icons.qr_code_scanner_rounded,
        title: 'Pemindaian barcode belum tersedia',
        message: 'Gunakan mode komposisi untuk membaca daftar bahan pada kemasan.',
        onComposition: () => setState(() => _barcode = false),
      );
      return;
    }
    final navigator = Navigator.of(context);
    final result = await context.read<ScanProvider>().scan(source);
    if (result != null && mounted && ModalRoute.isCurrentOf(context) == true) {
      navigator.pushNamed(AppRoutes.scanResult, arguments: result);
    }
  }

  String _busyMessage(ScanStatus status) => switch (status) {
        ScanStatus.pickingImage => 'Membuka pemilih gambar…',
        ScanStatus.recognizing => 'Membaca teks pada label…',
        _ => 'Mencocokkan dengan kamus bahan…',
      };

  Future<void> _showInfo({
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onComposition,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF10271F),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: const Color(0xFFA0FAD0)),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: Color(0xFFF3FCF7), fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(message, style: const TextStyle(color: Color(0xFFC0D8CD), fontSize: 14, height: 1.5)),
              if (onComposition != null) ...[
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    onComposition();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: const Color(0xFF042C20),
                  ),
                  child: const Text('Kembali ke komposisi'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
