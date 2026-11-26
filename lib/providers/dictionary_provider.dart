import 'package:flutter/foundation.dart';

import '../models/failures.dart';
import '../models/ingredient.dart';
import '../services/dictionary_service.dart';

enum DictionaryStatus { initial, loading, loaded, error }

class DictionaryProvider extends ChangeNotifier {
  DictionaryProvider(this._service);

  final DictionaryService _service;

  DictionaryStatus _status = DictionaryStatus.initial;
  List<Ingredient> _ingredients = const [];
  String _query = '';
  String? _errorMessage;

  DictionaryStatus get status => _status;
  List<Ingredient> get ingredients => _ingredients;
  String get query => _query;
  String? get errorMessage => _errorMessage;

  List<Ingredient> get filtered {
    final keyword = _query.trim().toLowerCase();
    if (keyword.isEmpty) return _ingredients;
    return _ingredients.where((item) {
      return item.name.toLowerCase().contains(keyword) ||
          item.description.toLowerCase().contains(keyword) ||
          item.aliases.any((alias) => alias.toLowerCase().contains(keyword));
    }).toList();
  }

  Ingredient? findById(String id) {
    for (final item in _ingredients) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> load() async {
    _status = DictionaryStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _ingredients = await _service.load();
      _status = DictionaryStatus.loaded;
    } on AppFailure catch (failure) {
      _errorMessage = failure.message;
      _status = DictionaryStatus.error;
    }
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }
}
