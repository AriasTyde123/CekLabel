import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ceklabel/models/family_profile.dart';
import 'package:ceklabel/models/risk_level.dart';
import 'package:ceklabel/providers/dictionary_provider.dart';
import 'package:ceklabel/providers/profile_provider.dart';
import 'package:ceklabel/providers/scan_provider.dart';
import 'package:ceklabel/providers/shopping_tip_provider.dart';
import 'package:ceklabel/routes.dart';
import 'package:ceklabel/screens/scan_result_screen.dart';
import 'package:ceklabel/services/detection_service.dart';
import 'package:ceklabel/services/dictionary_service.dart';
import 'package:ceklabel/services/history_service.dart';
import 'package:ceklabel/services/ocr_service.dart';
import 'package:ceklabel/services/profile_service.dart';
import 'package:ceklabel/services/shopping_tip_service.dart';

class _StubOcrService implements OcrService {
  _StubOcrService(this.text);

  final String text;

  @override
  Future<String?> pickImage(ScanSource source) async => 'label.jpg';

  @override
  Future<String> recognizeText(String imagePath) async => text;

  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('renders all 6 ScanResultScreen sections and supports interactive flows', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final dictionaryProvider = DictionaryProvider(DictionaryService());
    final profileProvider = ProfileProvider(ProfileService());
    final tipProvider = ShoppingTipProvider(ShoppingTipService(apiKey: ''));
    final ocr = _StubOcrService(
      'Biskuit Cokelat Krim\n'
      'Komposisi: Tepung Terigu, Whey, Lesitin Kedelai, Maltodekstrin, Tartrazin, Garam. '
      'Diproduksi di fasilitas yang juga memproses kacang tanah.',
    );
    final scanProvider = ScanProvider(ocr, DetectionService(), HistoryService());

    await dictionaryProvider.load();
    await profileProvider.saveProfile(const FamilyProfile(
      id: 'child',
      name: 'Anak',
      role: 'Anak',
      allergens: {'Susu', 'Kacang'},
      sensitivity: SensitivityLevel.severe,
    ));
    await profileProvider.saveProfile(const FamilyProfile(
      id: 'father',
      name: 'Ayah',
      role: 'Ayah',
      avoidHiddenSugar: true,
    ));

    scanProvider.updateDependencies(dictionaryProvider.ingredients, profileProvider.activeProfiles);
    final result = await scanProvider.scan(ScanSource.camera);
    expect(result, isNotNull);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DictionaryProvider>.value(value: dictionaryProvider),
          ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
          ChangeNotifierProvider<ScanProvider>.value(value: scanProvider),
          ChangeNotifierProvider<ShoppingTipProvider>.value(value: tipProvider),
        ],
        child: MaterialApp(
          home: ScanResultScreen(result: result),
          onGenerateRoute: AppRoutes.generate,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Top Status Banner
    expect(find.text('TIDAK AMAN'), findsOneWidget);
    expect(find.textContaining('alergen utama'), findsOneWidget);

    // 2. Product Info Card
    expect(find.text('Biskuit Cokelat Krim'), findsOneWidget);

    // Toggle bookmark -> persists to Safe List
    await tester.tap(find.byTooltip('Simpan ke Daftar Aman'));
    await tester.pumpAndSettle();
    expect(scanProvider.savedResults.length, 1);

    // 3. Multi-Profile Impact Card
    expect(find.text('Dampak Profil Keluarga'), findsOneWidget);
    expect(find.text('Anak'), findsOneWidget);
    expect(find.text('Ayah'), findsOneWidget);
    expect(find.textContaining('Bahaya (Susu'), findsOneWidget);
    expect(find.textContaining('Waspada (Gula Tersembunyi)'), findsOneWidget);

    // 4. Cross-Contamination Alert Box
    expect(find.text('Peringatan Kontaminasi Silang'), findsOneWidget);
    expect(find.textContaining('kacang tanah'), findsOneWidget);

    // 5. Detected Ingredients Breakdown + Bottom Sheet
    final breakdownTitle = find.text('Analisis Komposisi (Klik untuk arti)');
    await tester.scrollUntilVisible(breakdownTitle, 200);
    expect(breakdownTitle, findsOneWidget);

    final maltChip = find.text('Maltodekstrin (Gula)');
    await tester.scrollUntilVisible(maltChip, 200);
    await tester.ensureVisible(maltChip);
    await tester.pumpAndSettle();
    await tester.tap(maltChip);
    await tester.pumpAndSettle();
    expect(find.text('Artinya dalam bahasa awam'), findsOneWidget);

    // Dismiss bottom sheet
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // 6. Generic Shopping Tips with Offline Fallback indicator
    final tipsTitle = find.text('Tips Belanja Alternatif');
    await tester.scrollUntilVisible(tipsTitle, 250);
    await tester.ensureVisible(tipsTitle);
    await tester.pumpAndSettle();
    expect(tipsTitle, findsOneWidget);
    expect(find.text('Mode Offline'), findsOneWidget);
  });
}
