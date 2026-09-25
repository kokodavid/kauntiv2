import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_models.dart';
import 'package:kaunti47_v2/src/features/map_home/presentation/county_peek_sheet.dart';

MapHomeCountyBadge _machakos({String? hq, List<String> places = const []}) =>
    MapHomeCountyBadge(
      county: CountyPaths.byCode[16]!,
      state: MapHomeCountyBadgeState.locked,
      areaKm2: 5953,
      elevationM: 1619,
      headquarters: hq,
      placeNames: places,
    );

Future<void> _pump(
  WidgetTester tester,
  MapHomeCountyBadge badge, {
  bool isHome = false,
  VoidCallback? onOpen,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: CountyPeekSheet(badge: badge, isHome: isHome, onOpen: onOpen),
    ),
  ),
);

void main() {
  testWidgets('shows the county as the Explore feature card', (tester) async {
    await _pump(
      tester,
      _machakos(
        hq: 'Machakos',
        places: ["Machakos People's Park", 'Ol Donyo Sabuk'],
      ),
    );
    expect(find.text('UNCLAIMED'), findsOneWidget);
    expect(find.text('HQ · Machakos'), findsOneWidget);
    expect(find.text('Machakos County'), findsOneWidget);
    expect(
      find.text(
        "2 places to see, including Machakos People's Park and "
        'Ol Donyo Sabuk.',
      ),
      findsOneWidget,
    );
    expect(find.text('5,953 KM²'), findsOneWidget);
    expect(find.text('Open County'), findsOneWidget);
  });

  testWidgets('the home county says so; no HQ falls back', (tester) async {
    await _pump(tester, _machakos(), isHome: true);
    expect(find.text('HOME COUNTY'), findsOneWidget);
    // Caption and the card title both read "Machakos County".
    expect(find.text('Machakos County'), findsNWidgets(2));
    expect(find.text('No places on file yet for this county.'), findsOneWidget);
  });
}
