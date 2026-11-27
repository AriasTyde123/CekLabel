import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../models/failures.dart';
import '../models/risk_level.dart';

class OcrService {
  OcrService({ImagePicker? picker, TextRecognizer? recognizer})
      : _picker = picker ?? ImagePicker(),
        _recognizer = recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final ImagePicker _picker;
  final TextRecognizer _recognizer;

  Future<String?> pickImage(ScanSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == ScanSource.camera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2048,
      );
      return file?.path;
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied') {
        throw const OcrFailure('Izin galeri ditolak. Aktifkan izin foto di pengaturan perangkat.');
      }
      if (e.code == 'camera_access_denied') {
        throw const OcrFailure('Izin kamera ditolak. Aktifkan izin kamera di pengaturan perangkat.');
      }
      if (e.code == 'already_active') {
        throw const OcrFailure('Pemilih gambar sedang terbuka. Tunggu sebentar lalu coba lagi.');
      }
      throw const OcrFailure('Kamera atau galeri tidak dapat diakses. Periksa izin aplikasi.');
    } catch (_) {
      throw const OcrFailure('Kamera atau galeri tidak dapat diakses. Periksa izin aplikasi.');
    }
  }

  /// Recovers an image path if Android killed the activity while the gallery/camera picker was open.
  Future<String?> retrieveLostImagePath() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return null;
      return response.file?.path;
    } catch (_) {
      return null;
    }
  }

  Future<String> recognizeText(String imagePath) async {
    try {
      final result = await _recognizer.processImage(InputImage.fromFilePath(imagePath));
      final text = result.text.trim();
      if (text.isEmpty) {
        throw const OcrFailure('Teks tidak terbaca. Pastikan label komposisi jelas dan tidak buram.');
      }
      return text;
    } on OcrFailure {
      rethrow;
    } on PlatformException catch (e) {
      final detail = (e.message ?? e.code).trim();
      if (detail.isNotEmpty) {
        throw OcrFailure('Gagal memindai teks ($detail). Coba foto ulang atau pilih dari Galeri.');
      }
      throw const OcrFailure('Pemindai teks tidak tersedia di perangkat ini.');
    } catch (_) {
      throw const OcrFailure('Pemindai teks tidak tersedia di perangkat ini.');
    }
  }

  Future<void> dispose() => _recognizer.close();
}
