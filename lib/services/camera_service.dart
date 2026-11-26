import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import '../models/failures.dart';

/// Encapsulates live camera preview, torch control, and photo capture.
class CameraService {
  CameraController? _controller;
  bool _flashOn = false;

  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isFlashOn => _flashOn;
  CameraController? get controller => _controller;

  /// Builds a full-bleed aspect-preserving camera preview, or null if not ready.
  Widget? buildPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: previewSize.height,
        height: previewSize.width,
        child: CameraPreview(controller),
      ),
    );
  }

  Future<void> initialize() async {
    await dispose();
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw const CameraFailure('Kamera tidak ditemukan pada perangkat ini.');
      }
      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {
        // Some emulators or devices do not support flash control.
      }
      _flashOn = false;
    } on CameraFailure {
      await dispose();
      rethrow;
    } on CameraException catch (e) {
      await dispose();
      if (e.code == 'CameraAccessDenied' || e.code == 'CameraAccessDeniedWithoutPrompt') {
        throw const CameraFailure('Izin kamera ditolak. Aktifkan izin kamera di pengaturan perangkat.');
      }
      throw const CameraFailure('Gagal membuka kamera. Coba lagi atau pilih gambar dari galeri.');
    } catch (_) {
      await dispose();
      throw const CameraFailure('Gagal membuka kamera. Coba lagi atau pilih gambar dari galeri.');
    }
  }

  Future<bool> toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw const CameraFailure('Kamera belum siap untuk menyalakan lampu kilat.');
    }
    final next = !_flashOn;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      _flashOn = next;
      return _flashOn;
    } catch (_) {
      throw const CameraFailure('Lampu kilat tidak didukung pada kamera ini.');
    }
  }

  Future<String> takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw const CameraFailure('Kamera belum siap untuk mengambil foto.');
    }
    if (controller.value.isTakingPicture) {
      throw const CameraFailure('Sedang mengambil foto, mohon tunggu sebentar.');
    }
    try {
      final file = await controller.takePicture();
      return file.path;
    } catch (_) {
      throw const CameraFailure('Gagal mengambil foto. Coba lagi.');
    }
  }

  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    _flashOn = false;
    if (controller == null) return;
    try {
      if (controller.value.isInitialized) {
        await controller.setFlashMode(FlashMode.off);
      }
    } catch (_) {
      // Best effort turning off torch before disposing.
    }
    try {
      await controller.dispose();
    } catch (_) {
      // Ignore disposal errors when camera was already released.
    }
  }
}

