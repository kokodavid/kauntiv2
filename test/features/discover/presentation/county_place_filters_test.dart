import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/place_type.dart';
import 'package:kaunti47_v2/src/features/discover/domain/county_detail.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/county_place_filters.dart';

CountyDetailPlace _place(String id, PlaceType category) => CountyDetailPlace(
  id: id,
  title: id,
  description: '',
  category: category,
  saved: false,
);

void main() {
  final places = [
    _place('a', PlaceType.stay),
    _place('b', PlaceType.park),
    _place('c', PlaceType.stay),
  ];

  test('categories come from the places, in category order', () {
    expect(CountyPlaceFilters.categoriesIn(places), [
      PlaceType.park,
      PlaceType.stay,
    ]);
  });

  testWidgets('shows ALL first with counts and reports taps', (tester) async {
    PlaceType? picked = PlaceType.park;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountyPlaceFilters(
            places: places,
            selected: null,
            onSelected: (category) => picked = category,
          ),
        ),
      ),
    );

    expect(find.text('All · 3'), findsOneWidget);
    expect(find.text('Parks · 1'), findsOneWidget);
    expect(find.text('Stays · 2'), findsOneWidget);
    expect(find.text('Beaches · 0'), findsNothing);

    await tester.tap(find.text('Stays · 2'));
    expect(picked, PlaceType.stay);
    await tester.tap(find.text('All · 3'));
    expect(picked, isNull);
  });
}
