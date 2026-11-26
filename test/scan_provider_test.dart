import 'package:ceklabel/models/failures.dart';
import 'package:ceklabel/models/risk_level.dart';
import 'package:ceklabel/providers/scan_provider.dart';
import 'package:ceklabel/services/detection_service.dart';
import 'package:ceklabel/services/ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _OcrStub extends OcrService {
  String? path = 'label.jpg';
  String text = 'Air';
  bool fails = false;

  @override
  Future<String?> pickImage(ScanSource source) async => path;

  @override
  Future<String> recognizeText(String imagePath) async {
    if (fails) throw const OcrFailure('Teks tidak terbaca.');
    return text;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  test('stores completed scans newest first and omits canceled and failed scans', () async {
    final ocr = _OcrStub();
    final provider = ScanProvider(ocr, DetectionService());
    addTearDown(provider.dispose);

    final first = await provider.scan(ScanSource.gallery);
    ocr.text = 'Susu';
    final second = await provider.scan(ScanSource.camera);

    expect(first?.rawText, 'Air');
    expect(second?.rawText, 'Susu');
    expect(provider.history, [second, first]);

    ocr.fails = true;
    expect(await provider.scan(ScanSource.gallery), isNull);
    expect(provider.status, ScanStatus.error);

    ocr.path = null;
    expect(await provider.scan(ScanSource.gallery), isNull);
    expect(provider.history, [second, first]);
  });
}
