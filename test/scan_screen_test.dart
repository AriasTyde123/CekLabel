import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ceklabel/models/failures.dart';
import 'package:ceklabel/models/family_profile.dart';
import 'package:ceklabel/models/risk_level.dart';
import 'package:ceklabel/providers/dictionary_provider.dart';
import 'package:ceklabel/providers/profile_provider.dart';
import 'package:ceklabel/providers/scan_provider.dart';
import 'package:ceklabel/providers/shopping_tip_provider.dart';
import 'package:ceklabel/routes.dart';
import 'package:ceklabel/screens/scan_screen.dart';
import 'package:ceklabel/services/camera_service.dart';
import 'package:ceklabel/services/detection_service.dart';
import 'package:ceklabel/services/dictionary_service.dart';
import 'package:ceklabel/services/history_service.dart';
import 'package:ceklabel/services/ocr_service.dart';
import 'package:ceklabel/services/profile_service.dart';
import 'package:ceklabel/services/shopping_tip_service.dart';

class _FakeCameraService extends CameraService {
  _FakeCameraService({this.failInit = false});

  final bool failInit;
  bool _initialized = false;
  bool _flash = false;
  int takePictureCalls = 0;

  @override
  bool get isInitialized => _initialized;

  @override
  bool get isFlashOn => _flash;

  @override
  Widget? buildPreview() => _initialized ? const ColoredBox(key: Key('live-camera-preview'), color: Colors.black) : null;

  @override
  Future<void> initialize() async {
    if (failInit) {
      throw const CameraFailure('Izin kamera ditolak. Aktifkan izin kamera di pengaturan perangkat.');
    }
    _initialized = true;
  }

  @override
  Future<bool> toggleFlash() async {
    _flash = !_flash;
    return _flash;
  }

  @override
  Future<String> takePicture() async {
    takePictureCalls++;
    return 'captured_label.jpg';
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
    _flash = false;
  }
}

class _StubOcrService implements OcrService {
  int pickCalls = 0;
  ScanSource? lastSource;

  @override
  Future<String?> pickImage(ScanSource source) async {
    pickCalls++;
    lastSource = source;
    return 'picked_label.jpg';
  }

  @override
  Future<String?> retrieveLostImagePath() async => null;

  @override
  Future<String> recognizeText(String imagePath) async =>
      'Biskuit Cokelat Krim\nKomposisi: Whey, Maltodekstrin, Garam';

  @override
  Future<void> dispose() async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpScanner(
    WidgetTester tester, {
    required _FakeCameraService camera,
    required _StubOcrService ocr,
    List<FamilyProfile> profiles = const [],
  }) async {
    final dictionaryProvider = DictionaryProvider(DictionaryService());
    final profileProvider = ProfileProvider(ProfileService());
    final scanProvider = ScanProvider(ocr, DetectionService(), HistoryService());
    final tipProvider = ShoppingTipProvider(ShoppingTipService(apiKey: ''));

    await tester.runAsync(() async {
      await dictionaryProvider.load();
      for (final profile in profiles) {
        await profileProvider.saveProfile(profile);
      }
    });
    scanProvider.updateDependencies(dictionaryProvider.ingredients, profileProvider.activeProfiles);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DictionaryProvider>.value(value: dictionaryProvider),
          ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
          ChangeNotifierProvider<ScanProvider>.value(value: scanProvider),
          ChangeNotifierProvider<ShoppingTipProvider>.value(value: tipProvider),
        ],
        child: MaterialApp(
          home: ScanScreen(cameraService: camera),
          onGenerateRoute: AppRoutes.generate,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders live camera preview without simulation or barcode tab, toggles flash, and scans', (tester) async {
    final camera = _FakeCameraService();
    final ocr = _StubOcrService();

    await pumpScanner(
      tester,
      camera: camera,
      ocr: ocr,
      profiles: const [
        FamilyProfile(id: '1', name: 'Anak', role: 'Anak', allergens: {'Susu'}),
        FamilyProfile(id: '2', name: 'Ayah', role: 'Ayah', avoidHiddenSugar: true),
      ],
    );

    expect(find.byKey(const Key('live-camera-preview')), findsOneWidget);
    expect(find.text('KAMERA AKTIF'), findsOneWidget);
    expect(find.text('SIMULASI KAMERA'), findsNothing);
    expect(find.text('Scan Barcode'), findsNothing);
    expect(find.text('2 Profil'), findsOneWidget);

    // Toggle flash on & off
    await tester.tap(find.byTooltip('Nyalakan lampu kilat'));
    await tester.pumpAndSettle();
    expect(camera.isFlashOn, isTrue);
    expect(find.byTooltip('Matikan lampu kilat'), findsOneWidget);

    // Capture via live camera -> OCR -> navigates to ScanResultScreen
    await tester.tap(find.byTooltip('Ambil foto'));
    await tester.pumpAndSettle();

    expect(camera.takePictureCalls, 1);
    expect(find.text('Hasil Analisis'), findsOneWidget);
    expect(find.text('Biskuit Cokelat Krim'), findsOneWidget);
  });

  testWidgets('shows graceful fallback when live camera fails to initialize', (tester) async {
    final camera = _FakeCameraService(failInit: true);
    final ocr = _StubOcrService();

    await pumpScanner(tester, camera: camera, ocr: ocr);

    expect(find.text('PINDAI KOMPOSISI'), findsOneWidget);
    expect(find.text('Atur Profil'), findsOneWidget);
    expect(find.textContaining('Izin kamera ditolak'), findsOneWidget);
    expect(find.text('Kamera Sistem'), findsOneWidget);

    // Tapping capture falls back to system camera via image_picker
    await tester.tap(find.byTooltip('Ambil foto'));
    await tester.pumpAndSettle();

    expect(ocr.pickCalls, 1);
    expect(ocr.lastSource, ScanSource.camera);
    expect(find.text('Hasil Analisis'), findsOneWidget);
  });

  testWidgets('uploads image from gallery and navigates to ScanResultScreen', (tester) async {
    final camera = _FakeCameraService();
    final ocr = _StubOcrService();

    await pumpScanner(tester, camera: camera, ocr: ocr);

    await tester.tap(find.text('Galeri'));
    await tester.pumpAndSettle();

    expect(ocr.pickCalls, 1);
    expect(ocr.lastSource, ScanSource.gallery);
    expect(find.text('Hasil Analisis'), findsOneWidget);
    expect(find.text('Biskuit Cokelat Krim'), findsOneWidget);
  });
}

