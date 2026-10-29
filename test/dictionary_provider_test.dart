import 'package:ceklabel/models/failures.dart';
import 'package:ceklabel/models/ingredient.dart';
import 'package:ceklabel/models/risk_level.dart';
import 'package:ceklabel/providers/dictionary_provider.dart';
import 'package:ceklabel/services/dictionary_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDictionaryService extends DictionaryService {
  _FakeDictionaryService({required this.data, this.shouldFail = false});

  final List<Ingredient> data;
  final bool shouldFail;

  @override
  Future<List<Ingredient>> load() async {
    if (shouldFail) {
      throw const DictionaryLoadFailure('Gagal memuat berkas kamus.');
    }
    return List.unmodifiable(data);
  }
}

const _testIngredients = [
  Ingredient(
    id: 'susu',
    name: 'Susu Bubuk',
    aliases: ['milk powder'],
    category: IngredientCategory.allergen,
    allergenGroup: 'Susu',
    description: 'Alergen susu.',
    riskLevelDefault: RiskLevel.danger,
  ),
  Ingredient(
    id: 'maltodekstrin',
    name: 'Maltodekstrin',
    aliases: ['maltodextrin'],
    category: IngredientCategory.sugarAlias,
    allergenGroup: null,
    description: 'Pemanis tersembunyi.',
    riskLevelDefault: RiskLevel.caution,
  ),
  Ingredient(
    id: 'msg',
    name: 'Monosodium Glutamat',
    aliases: ['e621', 'vetsin'],
    category: IngredientCategory.additive,
    allergenGroup: null,
    description: 'Penyedap rasa.',
    riskLevelDefault: RiskLevel.caution,
  ),
];

void main() {
  test('load berhasil mengisi ingredients dan mengubah status ke loaded', () async {
    final service = _FakeDictionaryService(data: _testIngredients);
    final provider = DictionaryProvider(service);

    await provider.load();

    expect(provider.status, DictionaryStatus.loaded);
    expect(provider.ingredients.length, 3);
    expect(provider.errorMessage, isNull);
  });

  test('load gagal memperbarui status ke error dan menyimpan errorMessage', () async {
    final service = _FakeDictionaryService(data: [], shouldFail: true);
    final provider = DictionaryProvider(service);

    await provider.load();

    expect(provider.status, DictionaryStatus.error);
    expect(provider.errorMessage, 'Gagal memuat berkas kamus.');
  });

  test('setQuery menyaring bahan berdasarkan nama atau alias', () async {
    final provider = DictionaryProvider(_FakeDictionaryService(data: _testIngredients));
    await provider.load();

    provider.setQuery('e621');
    final results = provider.filtered();

    expect(results.length, 1);
    expect(results.first.name, 'Monosodium Glutamat');
  });

  test('toggleOnlyUserAllergens menyaring bahan sesuai alergen pengguna', () async {
    final provider = DictionaryProvider(_FakeDictionaryService(data: _testIngredients));
    await provider.load();

    provider.toggleOnlyUserAllergens(true);
    final results = provider.filtered({'Susu'});

    expect(results.length, 1);
    expect(results.first.name, 'Susu Bubuk');
  });

  test('setCategory menyaring bahan berdasarkan kategori tertentu', () async {
    final provider = DictionaryProvider(_FakeDictionaryService(data: _testIngredients));
    await provider.load();

    provider.setCategory(IngredientCategory.sugarAlias);
    final results = provider.filtered();

    expect(results.length, 1);
    expect(results.first.name, 'Maltodekstrin');
    expect(provider.selectedCategory, IngredientCategory.sugarAlias);
  });

  test('clearFilters mengatur ulang kategori, query, dan alergen saya', () async {
    final provider = DictionaryProvider(_FakeDictionaryService(data: _testIngredients));
    await provider.load();

    provider.setCategory(IngredientCategory.additive);
    provider.setQuery('msg');
    provider.clearFilters();

    expect(provider.selectedCategory, isNull);
    expect(provider.query, isEmpty);
    expect(provider.onlyUserAllergens, isFalse);
    expect(provider.filtered().length, 3);
  });

  test('findById mengembalikan bahan yang tepat atau null jika tidak ada', () async {
    final provider = DictionaryProvider(_FakeDictionaryService(data: _testIngredients));
    await provider.load();

    expect(provider.findById('susu')?.name, 'Susu Bubuk');
    expect(provider.findById('non_existent'), isNull);
  });
}
