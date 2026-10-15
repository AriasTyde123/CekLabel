import 'package:ceklabel/models/allergen_preference.dart';
import 'package:ceklabel/models/ingredient.dart';
import 'package:ceklabel/models/risk_level.dart';
import 'package:ceklabel/providers/dictionary_provider.dart';
import 'package:ceklabel/providers/preference_provider.dart';
import 'package:ceklabel/routes.dart';
import 'package:ceklabel/screens/dictionary_screen.dart';
import 'package:ceklabel/services/dictionary_service.dart';
import 'package:ceklabel/services/preference_service.dart';
import 'package:ceklabel/providers/scan_provider.dart';
import 'package:ceklabel/services/detection_service.dart';
import 'package:ceklabel/services/ocr_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDictionaryService extends DictionaryService {
  _FakeDictionaryService(this.data);
  final List<Ingredient> data;

  @override
  Future<List<Ingredient>> load() async => List.unmodifiable(data);
}

final _mockIngredients = [
  const Ingredient(
    id: 'susu',
    name: 'Susu Bubuk',
    aliases: ['milk powder', 'susu skim'],
    category: IngredientCategory.allergen,
    allergenGroup: 'Susu',
    description: 'Produk olahan susu sapi yang mengandung laktosa dan kasein.',
    riskLevelDefault: RiskLevel.danger,
  ),
  const Ingredient(
    id: 'maltodekstrin',
    name: 'Maltodekstrin',
    aliases: ['maltodextrin'],
    category: IngredientCategory.sugarAlias,
    allergenGroup: null,
    description: 'Bahan aditif karbohidrat yang berfungsi sebagai pengental dan pemanis tersembunyi.',
    riskLevelDefault: RiskLevel.caution,
  ),
  const Ingredient(
    id: 'monosodium_glutamat',
    name: 'Monosodium Glutamat',
    aliases: ['msg', 'e621', 'vetsin'],
    category: IngredientCategory.additive,
    allergenGroup: null,
    description: 'Penyedap rasa sintetis untuk memperkuat rasa gurih (umami).',
    riskLevelDefault: RiskLevel.caution,
  ),
];

Widget _buildTestApp({
  required DictionaryProvider dictProvider,
  required PreferenceProvider prefProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<DictionaryProvider>.value(value: dictProvider),
      ChangeNotifierProvider<PreferenceProvider>.value(value: prefProvider),
      ChangeNotifierProvider<ScanProvider>(
        create: (_) => ScanProvider(OcrService(), DetectionService()),
      ),
    ],
    child: const MaterialApp(
      home: DictionaryScreen(),
      onGenerateRoute: AppRoutes.generate,
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('menampilkan daftar bahan dan jumlah bahan saat dibuka (AC 2.1)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dictProvider = DictionaryProvider(_FakeDictionaryService(_mockIngredients));
    await dictProvider.load();
    final prefProvider = PreferenceProvider(PreferenceService());

    await tester.pumpWidget(_buildTestApp(dictProvider: dictProvider, prefProvider: prefProvider));
    await tester.pumpAndSettle();

    expect(find.text('Cari Bahan'), findsOneWidget);
    expect(find.text('3 bahan'), findsOneWidget);
    expect(find.text('Susu Bubuk'), findsOneWidget);
    expect(find.text('Maltodekstrin'), findsOneWidget);
    expect(find.text('Monosodium Glutamat'), findsOneWidget);
  });

  testWidgets('pencarian real-time menyaring bahan berdasarkan nama atau alias (AC 2.1)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dictProvider = DictionaryProvider(_FakeDictionaryService(_mockIngredients));
    await dictProvider.load();
    final prefProvider = PreferenceProvider(PreferenceService());

    await tester.pumpWidget(_buildTestApp(dictProvider: dictProvider, prefProvider: prefProvider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(SearchBar), 'e621');
    await tester.pumpAndSettle();

    expect(find.text('1 bahan'), findsOneWidget);
    expect(find.text('Monosodium Glutamat'), findsOneWidget);
    expect(find.text('Susu Bubuk'), findsNothing);
    expect(find.text('Maltodekstrin'), findsNothing);
  });

  testWidgets('menampilkan pesan jika pencarian tidak menemukan hasil (AC 2.3)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dictProvider = DictionaryProvider(_FakeDictionaryService(_mockIngredients));
    await dictProvider.load();
    final prefProvider = PreferenceProvider(PreferenceService());

    await tester.pumpWidget(_buildTestApp(dictProvider: dictProvider, prefProvider: prefProvider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(SearchBar), 'xyz123tidakada');
    await tester.pumpAndSettle();

    expect(find.text('0 bahan'), findsOneWidget);
    expect(find.text('Tidak ditemukan. Coba kata kunci lain.'), findsOneWidget);
  });

  testWidgets('filter chip "Alergen Saya" menyaring hanya bahan alergen pengguna (AC 2.2)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'preference_user_name': 'Budi',
      'preference_allergens': ['Susu'],
    });

    final dictProvider = DictionaryProvider(_FakeDictionaryService(_mockIngredients));
    await dictProvider.load();
    final prefProvider = PreferenceProvider(PreferenceService());
    await prefProvider.load();

    await tester.pumpWidget(_buildTestApp(dictProvider: dictProvider, prefProvider: prefProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alergen Saya'));
    await tester.pumpAndSettle();

    expect(find.text('Alergen Saya (1)'), findsOneWidget);
    expect(find.text('Susu Bubuk'), findsOneWidget);
    expect(find.text('Maltodekstrin'), findsNothing);
    expect(find.text('Monosodium Glutamat'), findsNothing);
  });

  testWidgets('menampilkan peringatan jika filter Alergen Saya aktif tetapi belum ada preferensi alergen (AC 2.5)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});

    final dictProvider = DictionaryProvider(_FakeDictionaryService(_mockIngredients));
    await dictProvider.load();
    final prefProvider = PreferenceProvider(PreferenceService());
    await prefProvider.load();

    await tester.pumpWidget(_buildTestApp(dictProvider: dictProvider, prefProvider: prefProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alergen Saya'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada alergen yang dipilih'), findsOneWidget);
    expect(find.text('Atur preferensi alergen Anda terlebih dahulu agar dapat difilter.'), findsOneWidget);
    expect(find.text('Atur Preferensi'), findsOneWidget);
  });

  testWidgets('menavigasi ke halaman detail bahan saat kartu ditekan (AC 2.4)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dictProvider = DictionaryProvider(_FakeDictionaryService(_mockIngredients));
    await dictProvider.load();
    final prefProvider = PreferenceProvider(PreferenceService());

    await tester.pumpWidget(_buildTestApp(dictProvider: dictProvider, prefProvider: prefProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Maltodekstrin'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Bahan'), findsOneWidget);
    expect(find.text('Artinya dalam bahasa awam'), findsOneWidget);
    expect(find.text('Nama lain di label'), findsOneWidget);
    expect(find.text('maltodextrin'), findsOneWidget);
  });
}
