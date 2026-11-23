import 'package:excellencecoachinghub/widgets/school/school_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Rwanda locations: official counts and the Huye → Ngoma → Butare chain', () async {
    final l = await RwandaLocations.load();
    expect(l.provinces(), ['Kigali City', 'Eastern', 'Northern', 'Southern', 'Western']);
    final districts = [for (final p in l.provinces()) ...l.districts(p)];
    expect(districts.length, 30);
    expect(l.districts('Southern'), contains('Huye'));
    expect(l.sectors('Southern', 'Huye'), containsAll(['Ngoma', 'Tumba', 'Mukura']));
    expect(l.cells('Southern', 'Huye', 'Ngoma'), containsAll(['Butare', 'Matyazo']));
    expect(l.villages('Southern', 'Huye', 'Ngoma', 'Butare'), isNotEmpty);
    // Case-insensitive lookups (old records typed by hand).
    expect(l.sectors('southern', 'huye'), contains('Ngoma'));
    expect(l.sectors('Southern', 'Nowhere'), isEmpty);
  });

  testWidgets('address fields: lower levels wait for the level above; saved address shows', (tester) async {
    Map<String, String>? last;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AddressFields(value: const {'province': 'Southern', 'district': 'Huye', 'sector': 'Ngoma'}, onChanged: (v) => last = v),
        ),
      ),
    ));
    await tester.runAsync(() => RwandaLocations.load());
    await tester.pumpAndSettle();
    expect(find.text('Ngoma'), findsWidgets);
    expect(find.text('Choose the cell first'), findsOneWidget); // village waits for the cell
    expect(last, isNull);
  });
}
