import 'package:ceklabel/models/family_profile.dart';
import 'package:ceklabel/providers/profile_provider.dart';
import 'package:ceklabel/services/profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('validates short name and empty filters with Indonesian messages', () {
    expect(ProfileProvider.validateName('A'), 'Nama minimal 2 karakter');
    expect(ProfileProvider.validateName('  '), 'Nama wajib diisi');
    expect(
      ProfileProvider.validateFilters(const FamilyProfile(id: '1', name: 'Anak')),
      'Pilih minimal 1 alergen atau filter tambahan',
    );
  });

  test('saves, toggles active state, deletes, and reloads multiple family profiles', () async {
    final provider = ProfileProvider(ProfileService());
    const child = FamilyProfile(
      id: 'p1',
      name: 'Anak',
      role: 'Anak',
      allergens: {'Susu', 'Kacang'},
      sensitivity: SensitivityLevel.severe,
    );
    const father = FamilyProfile(
      id: 'p2',
      name: 'Ayah',
      role: 'Ayah',
      avoidHiddenSugar: true,
    );

    expect(await provider.saveProfile(child), isTrue);
    expect(await provider.saveProfile(father), isTrue);
    expect(provider.activeProfiles.length, 2);

    expect(await provider.toggleActive('p2'), isTrue);
    expect(provider.activeProfiles.map((p) => p.id), ['p1']);

    final reloaded = ProfileProvider(ProfileService());
    await reloaded.load();
    expect(reloaded.profiles.length, 2);
    expect(reloaded.activeProfiles.map((p) => p.name), ['Anak']);

    expect(await reloaded.deleteProfile('p1'), isTrue);
    expect(reloaded.profiles.map((p) => p.id), ['p2']);
  });

  test('migrates legacy single-profile preference keys automatically', () async {
    SharedPreferences.setMockInitialValues({
      ProfileService.legacyNameKey: 'Budi',
      ProfileService.legacyAllergensKey: ['Kacang', 'Susu'],
    });

    final provider = ProfileProvider(ProfileService());
    await provider.load();

    expect(provider.profiles.length, 1);
    expect(provider.profiles.first.name, 'Budi');
    expect(provider.profiles.first.allergens, {'Kacang', 'Susu'});
  });
}

