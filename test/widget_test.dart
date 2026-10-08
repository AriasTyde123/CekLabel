import 'package:ceklabel/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Aplikasi CekLabel memuat layar utama dengan baik', (WidgetTester tester) async {
    await tester.pumpWidget(const CekLabelApp());
    await tester.pumpAndSettle();

    expect(find.text('CekLabel'), findsOneWidget);
    expect(find.text('Pindai Label'), findsOneWidget);
    expect(find.text('Cari Bahan'), findsOneWidget);
    expect(find.text('Atur Preferensi'), findsOneWidget);
  });
}
