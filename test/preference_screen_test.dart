import 'dart:async';

import 'package:ceklabel/models/allergen_preference.dart';
import 'package:ceklabel/providers/preference_provider.dart';
import 'package:ceklabel/screens/preference_screen.dart';
import 'package:ceklabel/services/preference_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DelayedService extends PreferenceService {
  _DelayedService() : super(prefs: null);

  @override
  Future<AllergenPreference> loadPreferences() {
    return Completer<AllergenPreference>().future;
  }
}

class _FailingService extends PreferenceService {
  _FailingService() : super(prefs: null);

  @override
  Future<AllergenPreference> loadPreferences() async {
    throw const PreferenceLoadFailure();
  }

  @override
  Future<void> savePreferences(AllergenPreference preference) async {
    throw const PreferenceSaveFailure();
  }
}

Future<void> _pumpScreen(
  WidgetTester tester,
  PreferenceProvider provider,
) {
  return tester.pumpWidget(
    ChangeNotifierProvider<PreferenceProvider>.value(
      value: provider,
      child: const MaterialApp(home: PreferenceScreen()),
    ),
  );
}

void main() {
  testWidgets('initial state shows empty hint', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = PreferenceProvider(service: PreferenceService());
    await _pumpScreen(tester, provider);
    expect(find.text('Belum ada data preferensi'), findsOneWidget);
  });

  testWidgets('loading state shows progress indicator', (tester) async {
    final provider = PreferenceProvider(service: _DelayedService());
    await _pumpScreen(tester, provider);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('loaded state shows form with saved data', (tester) async {
    SharedPreferences.setMockInitialValues({
      'preference_user_name': 'Budi',
      'preference_allergens': ['Kacang'],
    });
    final provider = PreferenceProvider(service: PreferenceService());
    await _pumpScreen(tester, provider);
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('Kacang'), findsOneWidget);
  });

  testWidgets('validation state shows errors on empty submit', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = PreferenceProvider(service: PreferenceService());
    await _pumpScreen(tester, provider);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Preferensi'));
    await tester.pump();
    expect(find.text('Nama wajib diisi'), findsOneWidget);
    expect(find.text('Pilih minimal 1 alergen'), findsWidgets);
  });

  testWidgets('success state saves and shows snackbar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = PreferenceProvider(service: PreferenceService());
    await _pumpScreen(tester, provider);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Sinta');
    await tester.tap(find.text('Susu'));
    await tester.pump();
    await tester.tap(find.text('Simpan Preferensi'));
    await tester.pumpAndSettle();
    expect(find.text('Preferensi tersimpan'), findsOneWidget);
  });

  testWidgets('error state shows message and retry', (tester) async {
    final provider = PreferenceProvider(service: _FailingService());
    await _pumpScreen(tester, provider);
    await tester.pumpAndSettle();
    expect(find.text('Gagal memuat preferensi. Coba lagi.'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });
}
