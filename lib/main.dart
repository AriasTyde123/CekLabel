import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/dictionary_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/scan_provider.dart';
import 'providers/shopping_tip_provider.dart';
import 'routes.dart';
import 'services/detection_service.dart';
import 'services/dictionary_service.dart';
import 'services/history_service.dart';
import 'services/ocr_service.dart';
import 'services/profile_service.dart';
import 'services/shopping_tip_service.dart';

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
        Provider<ShoppingTipService>(create: (_) => ShoppingTipService(), dispose: (_, service) => service.dispose()),
        ChangeNotifierProvider<DictionaryProvider>(create: (_) => DictionaryProvider(DictionaryService())..load()),
        ChangeNotifierProvider<ProfileProvider>(create: (_) => ProfileProvider(ProfileService())..load()),
        ChangeNotifierProxyProvider2<DictionaryProvider, ProfileProvider, ScanProvider>(
          create: (context) => ScanProvider(
            context.read<OcrService>(),
            context.read<DetectionService>(),
            HistoryService(),
          )..loadHistory(),
          update: (_, dictionary, profile, scan) =>
              scan!..updateDependencies(dictionary.ingredients, profile.activeProfiles),
        ),
        ChangeNotifierProvider<ShoppingTipProvider>(
          create: (context) => ShoppingTipProvider(context.read<ShoppingTipService>()),
        ),
      ],
      child: MaterialApp(
        title: 'CekLabel',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('id')],
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Plus Jakarta Sans',
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF10B981)),
        ),
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.generate,
      ),
    );
  }
}
