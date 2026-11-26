import 'package:flutter/material.dart';

import 'models/family_profile.dart';
import 'models/scan_result.dart';
import 'screens/dictionary_screen.dart';
import 'screens/ingredient_detail_screen.dart';
import 'screens/main_shell_screen.dart';
import 'screens/profile_form_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/scan_collection_screen.dart';
import 'screens/scan_result_screen.dart';
import 'screens/scan_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String scan = '/scan';
  static const String scanResult = '/scan/result';
  static const String dictionary = '/dictionary';
  static const String dictionaryDetail = '/dictionary/detail';
  static const String preferences = '/preferences';
  static const String profileForm = '/preferences/form';
  static const String history = '/history';
  static const String safeList = '/safe-list';

  static Route<dynamic> generate(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      scan => const ScanScreen(),
      scanResult => ScanResultScreen(result: settings.arguments is ScanResult ? settings.arguments as ScanResult : null),
      dictionary => const DictionaryScreen(),
      dictionaryDetail => IngredientDetailScreen(
          ingredientId: settings.arguments is String ? settings.arguments as String : null,
        ),
      preferences => const ProfileScreen(),
      profileForm => ProfileFormScreen(
          profile: settings.arguments is FamilyProfile ? settings.arguments as FamilyProfile : null,
        ),
      history => const ScanCollectionScreen(),
      safeList => const ScanCollectionScreen(safeOnly: true),
      _ => const MainShellScreen(),
    };
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
