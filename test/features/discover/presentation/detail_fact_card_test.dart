import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/detail_widgets.dart';

void main() {
  test('longer facts get a bigger share, within bounds', () {
    expect(DetailFactCard.flexFor('Governor', 'Moses Badilisha Kiarie'), 22);
    expect(DetailFactCard.flexFor('Source', 'Kaunti47'), 8);
    expect(DetailFactCard.flexFor('Headquarters', 'Ol Kalou'), 12);
    expect(DetailFactCard.flexFor('Type', 'Park'), 8);
    expect(DetailFactCard.flexFor('Governor', 'x' * 60), 24);
  });

  testWidgets('leaves out missing facts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DetailFactCard(
            facts: [('Governor', null), ('Source', 'Kaunti47')],
          ),
        ),
      ),
    );
    expect(find.text('Governor'), findsNothing);
    expect(find.text('Kaunti47'), findsOneWidget);
  });
}
