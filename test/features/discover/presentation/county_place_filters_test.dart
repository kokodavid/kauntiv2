import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/discover/domain/county_detail.dart';
import 'package:kaunti47_v2/src/features/discover/domain/place_category.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/county_place_filters.dart';

CountyDetailPlace _place(String id, PlaceCategory category) =>
    CountyDetailPlace(
      id: id,
      title: id,
      description: '',
      category: category,
      saved: false,
    );

void main() {
  final places = [
    _place('a', PlaceCategory.stay),
    _place('b', PlaceCategory.park),
    _place('c', PlaceCategory.stay),
  ];

  test('categories come from the places, in category order', () {
    expect(CountyPlaceFilters.categoriesIn(places), [
      PlaceCategory.park,
      PlaceCategory.stay,
    ]);
  });

  testWidgets('shows ALL first with counts and reports taps', (tester) async {
    PlaceCategory? picked = PlaceCategory.park;
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

    expect(find.text('ALL · 3'), findsOneWidget);
    expect(find.text('PARK · 1'), findsOneWidget);
    expect(find.text('STAY · 2'), findsOneWidget);
    expect(find.text('SHORE · 0'), findsNothing);

    await tester.tap(find.text('STAY · 2'));
    expect(picked, PlaceCategory.stay);
    await tester.tap(find.text('ALL · 3'));
    expect(picked, isNull);
  });
}
