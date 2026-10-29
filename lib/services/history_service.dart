import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_result.dart';

class HistoryService {
  static const String historyKey = 'scan_history';
  static const int maxHistory = 10;

  Future<List<ScanResult>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(historyKey) ?? const [];
      final results = <ScanResult>[];
      for (final raw in rawList) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          results.add(ScanResult.fromJson(decoded));
        } catch (_) {}
      }
      return List.unmodifiable(results);
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(ScanResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = (await load()).toList();
      current.removeWhere((item) => item.id == result.id);
      current.insert(0, result);
      final limited = current.take(maxHistory).map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(historyKey, limited);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(historyKey);
    } catch (_) {}
  }
}
