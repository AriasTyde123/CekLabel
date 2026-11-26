import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/failures.dart';
import '../models/scan_result.dart';

class HistoryService {
  static const String historyKey = 'scan_history_v2';

  /// Maximum number of unsaved scans kept. Items in the Safe List are never trimmed.
  static const int maxRecentScans = 50;

  Future<List<ScanResult>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(historyKey);
      if (raw == null) return const [];
      final decoded = jsonDecode(raw) as List;
      return [for (final item in decoded) ScanResult.fromJson(Map<String, dynamic>.from(item as Map))];
    } catch (_) {
      throw const HistoryFailure('Gagal memuat riwayat pindaian.');
    }
  }

  Future<void> save(List<ScanResult> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(historyKey, jsonEncode([for (final r in trim(results)) r.toJson()]));
      if (!saved) throw const HistoryFailure();
    } on HistoryFailure {
      rethrow;
    } catch (_) {
      throw const HistoryFailure();
    }
  }

  /// Keeps every saved item plus the newest [maxRecentScans] unsaved items.
  List<ScanResult> trim(List<ScanResult> results) {
    var recent = 0;
    return [
      for (final result in results)
        if (result.isSaved || recent++ < maxRecentScans) result,
    ];
  }
}

