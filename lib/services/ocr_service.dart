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
    } catch (_) {
      throw const OcrFailure('Kamera atau galeri tidak dapat diakses. Periksa izin aplikasi.');
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
    } catch (_) {
      throw const OcrFailure('Pemindai teks tidak tersedia di perangkat ini.');
    }
  }

  Future<void> dispose() => _recognizer.close();
}
