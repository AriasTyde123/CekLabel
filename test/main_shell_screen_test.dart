import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ceklabel/models/risk_level.dart';
import 'package:ceklabel/providers/dictionary_provider.dart';
import 'package:ceklabel/providers/preference_provider.dart';
import 'package:ceklabel/providers/scan_provider.dart';
import 'package:ceklabel/routes.dart';
import 'package:ceklabel/screens/main_shell_screen.dart';
import 'package:ceklabel/services/detection_service.dart';
import 'package:ceklabel/services/dictionary_service.dart';
import 'package:ceklabel/services/ocr_service.dart';
import 'package:ceklabel/services/preference_service.dart';
import 'package:ceklabel/widgets/home_cards.dart';

class _StubOcrService implements OcrService {
  @override
  Future<String?> pickImage(ScanSource source) async => null;

  @override
  Future<String> recognizeText(String imagePath) async => '';

  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('bottom navigation bar stays visible across all four tabs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final dictionaryProvider = DictionaryProvider(DictionaryService());
    final preferenceProvider = PreferenceProvider(PreferenceService());
    final scanProvider = ScanProvider(_StubOcrService(), DetectionService());

    await dictionaryProvider.load();
    await preferenceProvider.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DictionaryProvider>.value(value: dictionaryProvider),
          ChangeNotifierProvider<PreferenceProvider>.value(value: preferenceProvider),
          ChangeNotifierProvider<ScanProvider>.value(value: scanProvider),
        ],
        child: MaterialApp(
          home: const MainShellScreen(),
          onGenerateRoute: AppRoutes.generate,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeNav), findsOneWidget);
    expect(find.text('Profil Keluarga'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(HomeNav), matching: find.text('Riwayat')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeNav), findsOneWidget);
    expect(find.text('Riwayat Pindaian'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(HomeNav), matching: find.text('Daftar Aman')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeNav), findsOneWidget);
    expect(find.text('Belum ada hasil berisiko rendah'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(HomeNav), matching: find.text('Profil')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeNav), findsOneWidget);
    expect(find.text('Atur Preferensi'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(HomeNav), matching: find.text('Beranda')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeNav), findsOneWidget);
    expect(find.text('Profil Keluarga'), findsOneWidget);
  });
}
