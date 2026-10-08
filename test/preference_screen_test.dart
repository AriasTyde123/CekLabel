import 'package:ceklabel/providers/preference_provider.dart';
import 'package:ceklabel/screens/preference_screen.dart';
import 'package:ceklabel/services/preference_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp(PreferenceProvider provider) {
  return ChangeNotifierProvider<PreferenceProvider>.value(
    value: provider,
    child: const MaterialApp(home: PreferenceScreen()),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('menampilkan judul, field nama, daftar alergen, dan tombol aksi', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = PreferenceProvider(PreferenceService());
    await tester.pumpWidget(_buildTestApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('Atur Preferensi'), findsOneWidget);
    expect(find.text('Nama panggilan'), findsOneWidget);
    expect(find.text('Kacang'), findsOneWidget);
    expect(find.text('Susu'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);
    expect(find.text('Atur Ulang'), findsOneWidget);
  });

  testWidgets('menampilkan pesan validasi jika disimpan saat input belum valid', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = PreferenceProvider(PreferenceService());
    await tester.pumpWidget(_buildTestApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Nama wajib diisi'), findsOneWidget);
    expect(find.text('Pilih minimal 1 alergen'), findsOneWidget);
  });

  testWidgets('menyimpan preferensi berhasil dan memunculkan snackbar', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = PreferenceProvider(PreferenceService());
    await tester.pumpWidget(_buildTestApp(provider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Budi');
    await tester.tap(find.text('Kacang'));
    await tester.pump();

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Preferensi tersimpan'), findsOneWidget);
    expect(provider.savedUserName, 'Budi');
    expect(provider.savedAllergens.contains('Kacang'), isTrue);
  });

  testWidgets('menampilkan dialog konfirmasi saat tombol Atur Ulang ditekan', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = PreferenceProvider(PreferenceService());
    await tester.pumpWidget(_buildTestApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Atur Ulang'));
    await tester.pumpAndSettle();

    expect(find.text('Atur ulang preferensi?'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
  });
}
