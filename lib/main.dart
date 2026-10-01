import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/preference_provider.dart';
import 'screens/preference_screen.dart';
import 'services/preference_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PreferenceProvider(service: PreferenceService()),
      child: MaterialApp(
        title: 'CekLabel',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const PreferenceScreen(),
      ),
    );
  }
}
