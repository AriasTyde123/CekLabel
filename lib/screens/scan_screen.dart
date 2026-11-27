import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/failures.dart';
import '../models/family_profile.dart';
import '../models/risk_level.dart';
import '../providers/profile_provider.dart';
import '../providers/scan_provider.dart';
import '../routes.dart';
import '../services/camera_service.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/scanner_view.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.cameraService});

  final CameraService? cameraService;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  late final CameraService _camera;
  bool _ownsCamera = false;
  bool _cameraLoading = true;
  bool _capturing = false;
  bool _pickingWithPicker = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsCamera = widget.cameraService == null;
    _camera = widget.cameraService ?? CameraService();
    _initCamera(updateInitialState: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverLostScan());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_pickingWithPicker) return;
    if (state == AppLifecycleState.inactive) {
      _camera.dispose();
    } else if (state == AppLifecycleState.resumed && mounted && ModalRoute.isCurrentOf(context) == true) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsCamera) {
      _camera.dispose();
    }
    super.dispose();
  }

  Future<void> _recoverLostScan() async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final result = await context.read<ScanProvider>().recoverLostScan();
    if (result != null && mounted && ModalRoute.isCurrentOf(context) == true) {
      await navigator.pushNamed(AppRoutes.scanResult, arguments: result);
      if (mounted) _initCamera();
    }
  }

  Future<void> _initCamera({bool updateInitialState = true}) async {
    if (updateInitialState && mounted) {
      setState(() {
        _cameraLoading = true;
        _cameraError = null;
      });
    } else {
      _cameraLoading = true;
      _cameraError = null;
    }
    try {
      await _camera.initialize();
      if (!mounted) return;
      setState(() => _cameraLoading = false);
    } on CameraFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _cameraLoading = false;
        _cameraError = failure.message;
      });
    }
  }

  Future<void> _toggleFlash() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _camera.toggleFlash();
      if (mounted) setState(() {});
    } on CameraFailure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _capture() async {
    final scanProvider = context.read<ScanProvider>();
    if (_capturing || _pickingWithPicker || scanProvider.isBusy) return;

    // If live camera preview is unavailable, fall back to system camera via image_picker.
    if (!_camera.isInitialized) {
      await _scanWithPicker(ScanSource.camera);
      return;
    }

    setState(() => _capturing = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await _camera.takePicture();
      if (!mounted) return;
      final result = await scanProvider.scanImageFile(path);
      if (result != null && mounted && ModalRoute.isCurrentOf(context) == true) {
        await _camera.dispose();
        await navigator.pushNamed(AppRoutes.scanResult, arguments: result);
        if (mounted) _initCamera();
      }
    } on CameraFailure catch (failure) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _scanWithPicker(ScanSource source) async {
    final scanProvider = context.read<ScanProvider>();
    if (_pickingWithPicker || _capturing || scanProvider.isBusy) return;

    setState(() => _pickingWithPicker = true);
    final navigator = Navigator.of(context);
    // Release live camera cleanly before opening Android Photo Picker / system camera to avoid lifecycle races.
    if (_ownsCamera && _camera.isInitialized) {
      await _camera.dispose();
    }

    try {
      final result = await scanProvider.scan(source);
      if (result != null && mounted && ModalRoute.isCurrentOf(context) == true) {
        await navigator.pushNamed(AppRoutes.scanResult, arguments: result);
      }
    } finally {
      if (mounted) {
        setState(() => _pickingWithPicker = false);
        if (ModalRoute.isCurrentOf(context) == true && !_camera.isInitialized && _ownsCamera) {
          _initCamera();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<ScanProvider>();
    final activeProfiles = context.watch<ProfileProvider>().activeProfiles;
    final busy = _capturing || _pickingWithPicker || scan.isBusy;

    final String? displayError;
    final String? secondaryLabel;
    VoidCallback? secondaryAction;
    if (scan.status == ScanStatus.error && scan.errorMessage != null) {
      displayError = scan.errorMessage;
      secondaryLabel = 'Pilih Galeri';
      secondaryAction = () {
        scan.reset();
        _scanWithPicker(ScanSource.gallery);
      };
    } else if (_cameraError != null && !_camera.isInitialized) {
      displayError = _cameraError;
      secondaryLabel = 'Kamera Sistem';
      secondaryAction = () => _scanWithPicker(ScanSource.camera);
    } else {
      displayError = null;
      secondaryLabel = null;
      secondaryAction = null;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF091813),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF091813),
        body: ScannerView(
          preview: _camera.buildPreview(),
          cameraReady: _camera.isInitialized,
          cameraLoading: _cameraLoading,
          flash: _camera.isFlashOn,
          busy: busy,
          activeProfileCount: activeProfiles.length,
          hint: busy
              ? _busyMessage(scan.status)
              : 'Arahkan kamera ke daftar komposisi di kemasan lalu ketuk tombol foto',
          error: displayError,
          secondaryActionLabel: secondaryLabel,
          onSecondaryAction: secondaryAction,
          onClose: () => Navigator.maybePop(context),
          onFlash: _toggleFlash,
          onHelp: () => _showHelpSheet(),
          onGallery: () => _scanWithPicker(ScanSource.gallery),
          onCapture: _capture,
          onProfiles: () => _showProfilesSheet(activeProfiles),
          onRetry: () {
            if (scan.status == ScanStatus.error) {
              scan.reset();
            } else {
              _initCamera();
            }
          },
        ),
      ),
    );
  }

  String _busyMessage(ScanStatus status) {
    if (_capturing && status == ScanStatus.initial) return 'Mengambil foto label…';
    return switch (status) {
      ScanStatus.pickingImage => 'Membuka pemilih gambar…',
      ScanStatus.recognizing => 'Membaca teks pada label…',
      _ => 'Mencocokkan dengan kamus bahan…',
    };
  }

  Future<void> _showHelpSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF10271F),
      builder: (sheetContext) => const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline_rounded, size: 28, color: Color(0xFFA0FAD0)),
              SizedBox(height: 12),
              Text(
                'Cara memindai label',
                style: TextStyle(color: Color(0xFFF3FCF7), fontSize: 21, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text(
                '1. Ratakan kemasan dan arahkan daftar komposisi ke dalam bingkai.\n'
                '2. Hindari pantulan cahaya, atau nyalakan lampu kilat jika ruangan redup.\n'
                '3. Ketuk tombol foto untuk memindai, atau pilih foto label dari Galeri.',
                style: TextStyle(color: Color(0xFFC0D8CD), fontSize: 14, height: 1.55),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showProfilesSheet(List<FamilyProfile> activeProfiles) {
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
              const Icon(Icons.group_outlined, size: 28, color: Color(0xFFA0FAD0)),
              const SizedBox(height: 12),
              const Text(
                'Profil yang dicek',
                style: TextStyle(color: Color(0xFFF3FCF7), fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (activeProfiles.isEmpty)
                const Text(
                  'Belum ada profil aktif. Tambahkan profil keluarga agar sistem mendeteksi alergen khusus keluarga Anda.',
                  style: TextStyle(color: Color(0xFFC0D8CD), fontSize: 14, height: 1.5),
                )
              else ...[
                for (final profile in activeProfiles) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        ProfileAvatar(profile: profile, radius: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${profile.name} · ${profile.role}',
                                style: const TextStyle(
                                  color: Color(0xFFF3FCF7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                profile.summary,
                                style: const TextStyle(color: Color(0xFFC0D8CD), fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(
                      context,
                      activeProfiles.isEmpty ? AppRoutes.profileForm : AppRoutes.preferences,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: const Color(0xFF042C20),
                  ),
                  child: Text(activeProfiles.isEmpty ? 'Tambah Profil Keluarga' : 'Atur Profil Keluarga'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
