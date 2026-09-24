import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/detection/presentation/county_arrival_sheet.dart';
import 'package:kaunti47_v2/src/features/discover/domain/county_detail.dart';
import 'package:kaunti47_v2/src/features/discover/domain/place_category.dart';

CountyDetailPlace _place(String id, {bool saved = false}) => CountyDetailPlace(
  id: id,
  title: 'Place $id',
  description: 'About $id',
  category: PlaceCategory.park,
  saved: saved,
);

CountyDetailData _nairobi(List<CountyDetailPlace> places) => CountyDetailData(
  county: CountyPaths.byCode[47]!,
  aboutBlurb: '',
  quickFacts: const CountyQuickFacts(),
  places: places,
  personalStatusLabel: 'NOT VISITED YET',
  isHeld: false,
);

Future<void> _open(
  WidgetTester tester,
  CountyDetailData data, {
  void Function(int)? onOpenCounty,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCountyArrivalSheet(
              context,
              data: data,
              onOpenCounty: onOpenCounty,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the county card and four places, saved first', (
    tester,
  ) async {
    final opened = <int>[];
    await _open(
      tester,
      _nairobi([for (var i = 1; i <= 5; i++) _place('$i', saved: i == 5)]),
      onOpenCounty: opened.add,
    );

    expect(find.text('Welcome to Nairobi'), findsOneWidget);
    expect(
      find.text("You've just crossed in. 5 places worth the detour."),
      findsOneWidget,
    );
    expect(find.text("YOU'RE HERE"), findsOneWidget);
    expect(find.text('Places to visit'), findsOneWidget);
    expect(find.text('All 5 places in Nairobi →'), findsOneWidget);
    expect(find.textContaining('Place '), findsNWidgets(4));
    expect(find.text('Place 5'), findsOneWidget);
    expect(find.text('Place 4'), findsNothing);

    // The county card opens County Detail and closes the sheet.
    await tester.tap(find.text("YOU'RE HERE"));
    await tester.pumpAndSettle();
    expect(opened, [47]);
    expect(find.text('Welcome to Nairobi'), findsNothing);
  });

  testWidgets('an empty county says so and dismisses', (tester) async {
    await _open(tester, _nairobi(const []));
    const empty = "You've just crossed in. Nothing on file here yet.";
    expect(find.text(empty), findsOneWidget);
    expect(find.text('Places to visit'), findsNothing);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text(empty), findsNothing);
  });
}
