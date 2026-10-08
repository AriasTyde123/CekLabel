import 'package:ceklabel/providers/preference_provider.dart';
import 'package:ceklabel/providers/preference_status.dart';
import 'package:ceklabel/services/preference_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('rejects short name and empty allergens with Indonesian messages', () async {
    final provider = PreferenceProvider(PreferenceService());
    provider.setUserName('Al');

    expect(await provider.save(), isFalse);
    expect(provider.nameError, 'Nama minimal 3 karakter');
    expect(provider.allergenError, 'Pilih minimal 1 alergen');
  });

  test('persists and reloads preferences', () async {
    final provider = PreferenceProvider(PreferenceService());
    provider
      ..setUserName('Budi')
      ..toggleAllergen('Kacang', true)
      ..toggleAllergen('Susu', true);

    expect(await provider.save(), isTrue);
    expect(provider.status, PreferenceStatus.success);

    final reloaded = PreferenceProvider(PreferenceService());
    await reloaded.load();
    expect(reloaded.savedUserName, 'Budi');
    expect(reloaded.savedAllergens, {'Kacang', 'Susu'});
  });
}
