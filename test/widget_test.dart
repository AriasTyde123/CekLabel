import 'package:ceklabel/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App shows preference screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Preferensi Alergen'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Simpan Preferensi'), findsOneWidget);
  });
}
