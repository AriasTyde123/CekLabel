import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ceklabel/models/family_profile.dart';
import 'package:ceklabel/providers/profile_provider.dart';
import 'package:ceklabel/routes.dart';
import 'package:ceklabel/screens/emergency_card_screen.dart';
import 'package:ceklabel/services/profile_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpCard(WidgetTester tester, List<FamilyProfile> profiles) async {
    final profileProvider = ProfileProvider(ProfileService());
    await tester.runAsync(() async {
      for (final profile in profiles) {
        await profileProvider.saveProfile(profile);
      }
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<ProfileProvider>.value(
        value: profileProvider,
        child: MaterialApp(
          home: const EmergencyCardScreen(),
          onGenerateRoute: AppRoutes.generate,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders active profiles, toggles ID/EN language, and filters by member', (tester) async {
    await pumpCard(tester, const [
      FamilyProfile(
        id: 'child',
        name: 'Bima',
        role: 'Anak',
        allergens: {'Susu', 'Kacang'},
        sensitivity: SensitivityLevel.severe,
      ),
      FamilyProfile(
        id: 'father',
        name: 'Andi',
        role: 'Ayah',
        allergens: {'Udang'},
        sensitivity: SensitivityLevel.mild,
        avoidHiddenSugar: true,
      ),
    ]);

    // Default Indonesian
    expect(find.text('Kartu Darurat Alergi'), findsOneWidget);
    expect(find.text('PERINGATAN ALERGI MAKANAN'), findsOneWidget);
    expect(find.text('Tersedia 100% Offline'), findsOneWidget);
    expect(find.text('ALERGI BERAT · RISIKO ANAFILAKSIS'), findsOneWidget);
    expect(find.text('Susu'), findsOneWidget);
    expect(find.text('Kacang'), findsOneWidget);

    // Toggle to English
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text('Emergency Allergy Card'), findsOneWidget);
    expect(find.text('FOOD ALLERGY ALERT'), findsOneWidget);
    expect(find.text('100% Offline Ready'), findsOneWidget);
    expect(find.text('SEVERE ALLERGY · ANAPHYLAXIS RISK'), findsOneWidget);
    expect(find.text('Milk / Dairy'), findsOneWidget);
    expect(find.text('Peanuts / Nuts'), findsOneWidget);
    expect(find.text('Child'), findsOneWidget);

    // Filter to single member (Andi)
    await tester.tap(find.widgetWithText(ChoiceChip, 'Andi'));
    await tester.pumpAndSettle();

    expect(find.text('Shrimp / Shellfish'), findsOneWidget);
    expect(find.text('Avoid hidden sugars'), findsOneWidget);
    expect(find.text('Milk / Dairy'), findsNothing);
  });

  testWidgets('shows empty state with CTA when no active allergy profiles exist', (tester) async {
    await pumpCard(tester, const []);

    expect(find.text('Belum Ada Profil Alergi Aktif'), findsOneWidget);
    expect(find.text('Tambah Profil Keluarga'), findsOneWidget);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text('No Active Allergy Profiles Yet'), findsOneWidget);
    expect(find.text('Add Family Profile'), findsOneWidget);
  });
}

