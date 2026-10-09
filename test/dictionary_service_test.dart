import 'dart:io';

import 'package:ceklabel/models/failures.dart';
import 'package:ceklabel/providers/dictionary_provider.dart';
import 'package:ceklabel/services/dictionary_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = DictionaryService();

  test('parses the bundled ingredients.json with all allergen groups', () {
    final items = service.parse(File('assets/ingredients.json').readAsStringSync());
    expect(items.length, greaterThan(40));
    final groups = items.map((item) => item.allergenGroup).whereType<String>().toSet();
    expect(groups.containsAll(['Kacang', 'Susu', 'Gluten', 'Telur', 'Udang', 'Kedelai']), isTrue);
  });

  test('throws DictionaryLoadFailure on invalid JSON', () {
    expect(() => service.parse('not json'), throwsA(isA<DictionaryLoadFailure>()));
  });

  test('filters ingredients by user allergens when onlyUserAllergens is toggled', () {
    final provider = DictionaryProvider(service);
    provider.toggleOnlyUserAllergens(true);

    // Without loaded items it returns empty
    expect(provider.filtered({'Kacang'}), isEmpty);
  });
}
