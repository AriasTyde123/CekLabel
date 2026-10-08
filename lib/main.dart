import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/dictionary_provider.dart';
import 'providers/preference_provider.dart';
import 'providers/scan_provider.dart';
import 'routes.dart';
import 'services/detection_service.dart';
import 'services/dictionary_service.dart';
import 'services/ocr_service.dart';
import 'services/preference_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CekLabelApp());
}

class CekLabelApp extends StatelessWidget {
  const CekLabelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<OcrService>(create: (_) => OcrService(), dispose: (_, service) => service.dispose()),
        Provider<DetectionService>(create: (_) => DetectionService()),
        ChangeNotifierProvider<DictionaryProvider>(create: (_) => DictionaryProvider(DictionaryService())..load()),
        ChangeNotifierProvider<PreferenceProvider>(create: (_) => PreferenceProvider(PreferenceService())..load()),
        ChangeNotifierProxyProvider2<DictionaryProvider, PreferenceProvider, ScanProvider>(
          create: (context) => ScanProvider(context.read<OcrService>(), context.read<DetectionService>()),
          update: (_, dictionary, preference, scan) =>
              scan!..updateDependencies(dictionary.ingredients, preference.savedAllergens),
        ),
      ],
      child: MaterialApp(
        title: 'CekLabel',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D5B)),
        ),
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.generate,
      ),
    );
  }
}
