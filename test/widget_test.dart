import 'package:ceklabel/main.dart';
import 'package:ceklabel/models/detected_ingredient.dart';
import 'package:ceklabel/models/ingredient.dart';
import 'package:ceklabel/models/risk_level.dart';
import 'package:ceklabel/models/scan_result.dart';
import 'package:ceklabel/providers/dictionary_provider.dart';
import 'package:ceklabel/providers/preference_provider.dart';
import 'package:ceklabel/providers/scan_provider.dart';
import 'package:ceklabel/routes.dart';
import 'package:ceklabel/services/detection_service.dart';
import 'package:ceklabel/services/dictionary_service.dart';
import 'package:ceklabel/services/history_service.dart';
import 'package:ceklabel/services/ocr_service.dart';
import 'package:ceklabel/services/preference_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDictionaryService extends DictionaryService {
  @override
  Future<List<Ingredient>> load() async => const [
        Ingredient(
          id: 'susu',
          name: 'Susu Bubuk',
          aliases: ['milk'],
          category: IngredientCategory.allergen,
          allergenGroup: 'Susu',
          description: 'Alergen susu.',
          riskLevelDefault: RiskLevel.danger,
        ),
      ];
}

Widget _buildHomeTestApp({
  required DictionaryProvider dictProvider,
  required PreferenceProvider prefProvider,
  required ScanProvider scanProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<DictionaryProvider>.value(value: dictProvider),
      ChangeNotifierProvider<PreferenceProvider>.value(value: prefProvider),
      ChangeNotifierProvider<ScanProvider>.value(value: scanProvider),
    ],
    child: const MaterialApp(
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.generate,
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Aplikasi CekLabel memuat layar utama dengan baik', (WidgetTester tester) async {
    await tester.pumpWidget(const CekLabelApp());
    await tester.pumpAndSettle();

    expect(find.text('CekLabel'), findsOneWidget);
    expect(find.text('Pindai Label'), findsOneWidget);
    expect(find.text('Cari Bahan'), findsOneWidget);
    expect(find.text('Atur Preferensi'), findsOneWidget);
  });

  testWidgets('Layar utama menampilkan riwayat pindaian dan dapat membukanya', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final scan1 = ScanResult.create(
      rawText: 'Komposisi: susu, gula',
      detected: [
        const DetectedIngredient(
          ingredientId: 'susu',
          ingredientName: 'Susu',
          matchedKeyword: 'susu',
          category: IngredientCategory.allergen,
          allergenGroup: 'Susu',
          riskLevel: RiskLevel.danger,
          description: 'Alergen susu.',
        ),
      ],
    );

    final scan2 = ScanResult.create(
      rawText: 'Komposisi: garam',
      detected: const [],
    );

    final historyService = HistoryService();
    await historyService.add(scan2);
    await historyService.add(scan1);

    final dictProvider = DictionaryProvider(_FakeDictionaryService());
    await dictProvider.load();
    final prefProvider = PreferenceProvider(PreferenceService());
    final scanProvider = ScanProvider(OcrService(), DetectionService(), historyService);
    await scanProvider.loadHistory();

    await tester.pumpWidget(_buildHomeTestApp(
      dictProvider: dictProvider,
      prefProvider: prefProvider,
      scanProvider: scanProvider,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Pindaian terakhir'), findsOneWidget);
    expect(find.text('Ditemukan 1 bahan berisiko'), findsOneWidget);
    expect(find.text('Riwayat Pindaian (2)'), findsOneWidget);

    await tester.tap(find.text('Pindaian terakhir'));
    await tester.pumpAndSettle();

    expect(find.text('Hasil Pindaian'), findsOneWidget);
    expect(find.text('Susu'), findsOneWidget);
  });
}
