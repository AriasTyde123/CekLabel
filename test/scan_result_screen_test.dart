import 'package:ceklabel/models/detected_ingredient.dart';
import 'package:ceklabel/models/ingredient.dart';
import 'package:ceklabel/models/risk_level.dart';
import 'package:ceklabel/models/scan_result.dart';
import 'package:ceklabel/providers/scan_provider.dart';
import 'package:ceklabel/screens/scan_result_screen.dart';
import 'package:ceklabel/services/detection_service.dart';
import 'package:ceklabel/services/ocr_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _buildTestApp({
  required ScanResult? result,
  ScanProvider? scanProvider,
}) {
  final provider = scanProvider ?? ScanProvider(OcrService(), DetectionService());
  return ChangeNotifierProvider<ScanProvider>.value(
    value: provider,
    child: MaterialApp(
      home: ScanResultScreen(result: result),
    ),
  );
}

void main() {
  testWidgets('menampilkan banner merah bahaya saat alergen pengguna terdeteksi (AC 1.1)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final detectedAllergen = const DetectedIngredient(
      ingredientId: 'susu',
      ingredientName: 'Susu',
      matchedKeyword: 'susu bubuk',
      category: IngredientCategory.allergen,
      allergenGroup: 'Susu',
      riskLevel: RiskLevel.danger,
      description: 'Dapat memicu alergi bagi penderita intoleransi atau alergi susu.',
    );

    final result = ScanResult.create(
      rawText: 'Komposisi: susu bubuk, gula, perisa vanila',
      detected: [detectedAllergen],
    );

    await tester.pumpWidget(_buildTestApp(result: result));
    await tester.pumpAndSettle();

    expect(find.text('Hasil Pindaian'), findsOneWidget);
    expect(find.text('Awas! Mengandung Susu'), findsOneWidget);
    expect(find.text('Ditemukan 1 bahan berisiko'), findsOneWidget);
    expect(find.text('Susu'), findsOneWidget);
    expect(find.text('Terbaca: "susu bubuk"'), findsOneWidget);
    expect(find.text('Bahaya'), findsOneWidget);
  });

  testWidgets('menampilkan banner kuning kehati-hatian untuk gula tersembunyi (AC 1.2)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final detectedSugar = const DetectedIngredient(
      ingredientId: 'maltodekstrin',
      ingredientName: 'Maltodekstrin',
      matchedKeyword: 'maltodextrin',
      category: IngredientCategory.sugarAlias,
      allergenGroup: null,
      riskLevel: RiskLevel.caution,
      description: 'Gula tersembunyi dari pati yang cepat menaikkan gula darah.',
    );

    final result = ScanResult.create(
      rawText: 'Komposisi: maltodextrin, garam',
      detected: [detectedSugar],
    );

    await tester.pumpWidget(_buildTestApp(result: result));
    await tester.pumpAndSettle();

    expect(find.text('Kemungkinan Mengandung Gula Tersembunyi'), findsOneWidget);
    expect(find.text('Ditemukan 1 bahan berisiko'), findsOneWidget);
    expect(find.text('Maltodekstrin'), findsOneWidget);
    expect(find.text('Waspada'), findsOneWidget);
  });

  testWidgets('menampilkan rincian bahan terdeteksi dan expandable teks asli (AC 1.3)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const rawText = 'Komposisi: Susu Skim Bubuk, Sukrosa, Minyak Nabati';
    final result = ScanResult.create(
      rawText: rawText,
      detected: [
        const DetectedIngredient(
          ingredientId: 'susu',
          ingredientName: 'Susu',
          matchedKeyword: 'susu skim bubuk',
          category: IngredientCategory.allergen,
          allergenGroup: 'Susu',
          riskLevel: RiskLevel.danger,
          description: 'Alergen susu.',
        ),
      ],
    );

    await tester.pumpWidget(_buildTestApp(result: result));
    await tester.pumpAndSettle();

    expect(find.text('Bahan terdeteksi (1)'), findsOneWidget);
    expect(find.text('Lihat Teks Asli'), findsOneWidget);

    await tester.tap(find.text('Lihat Teks Asli'));
    await tester.pumpAndSettle();

    expect(find.text(rawText), findsOneWidget);
    expect(find.text('Pindai Lagi'), findsOneWidget);
  });

  testWidgets('menampilkan empty state jika hasil pindaian kosong atau null', (tester) async {
    await tester.pumpWidget(_buildTestApp(result: null));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada hasil pindaian'), findsOneWidget);
    expect(find.text('Pindai label komposisi terlebih dahulu.'), findsOneWidget);
  });
}
