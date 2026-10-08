import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/failures.dart';
import '../models/ingredient.dart';

class DictionaryService {
  static const String assetPath = 'assets/ingredients.json';

  Future<List<Ingredient>> load() async {
    try {
      final source = await rootBundle.loadString(assetPath);
      return parse(source);
    } on DictionaryLoadFailure {
      rethrow;
    } catch (_) {
      throw const DictionaryLoadFailure();
    }
  }

  List<Ingredient> parse(String source) {
    try {
      final decoded = jsonDecode(source) as List<dynamic>;
      final items = decoded.map((entry) => Ingredient.fromJson(entry as Map<String, dynamic>)).toList();
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return List.unmodifiable(items);
    } catch (_) {
      throw const DictionaryLoadFailure('Format kamus bahan tidak valid.');
    }
  }
}
