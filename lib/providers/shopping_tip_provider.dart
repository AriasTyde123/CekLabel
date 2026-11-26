import 'package:flutter/foundation.dart';

import '../models/shopping_tips.dart';
import '../services/shopping_tip_service.dart';

class ShoppingTipProvider extends ChangeNotifier {
  ShoppingTipProvider(this._service);

  final ShoppingTipService _service;
  final Map<String, ShoppingTips> _cache = {};
  final Set<String> _loading = {};

  ShoppingTips? tipsFor(TipRequest request) => _cache[request.cacheKey];

  bool isLoading(TipRequest request) => _loading.contains(request.cacheKey);

  Future<void> load(TipRequest request) async {
    final key = request.cacheKey;
    if (_cache.containsKey(key) || _loading.contains(key)) return;
    _loading.add(key);
    notifyListeners();
    ShoppingTips tips;
    try {
      tips = await _service.generate(request);
    } catch (_) {
      tips = ShoppingTips(tips: _service.localTips(request), isOffline: true);
    }
    _cache[key] = tips;
    _loading.remove(key);
    notifyListeners();
  }
}

