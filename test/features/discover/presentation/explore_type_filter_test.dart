import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/place_type.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_board.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_filters.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/explore_dock.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/explore_dock_types.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/explore_filter_sheet.dart';

// Ten types: more than the sheet shows before "Show all".
final _manyTypes = [
  for (final type in PlaceType.all.take(10))
    ExploreDockType(type: type, count: 1, isInterest: false),
];

const _types = [
  ExploreDockType(type: PlaceType.waterfall, count: 2, isInterest: true),
  ExploreDockType(type: PlaceType.lake, count: 1, isInterest: false),
];

Future<ExploreFilters?> _open(
  WidgetTester tester, {
  ExploreFilters initial = const ExploreFilters.none(),
  List<ExploreDockType> types = _types,
  required Future<void> Function() act,
}) async {
  ExploreFilters? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await showExploreFilterSheet(
                context,
                initial: initial,
                hasLocation: false,
                unclaimedCountyCount: 0,
                countFor: (filters) => filters.isEmpty ? 3 : 1,
                types: types,
                totalCount: 3,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await act();
  return result;
}

void main() {
  test('withTypes sets none, one or several types', () {
    const none = ExploreFilters.none();
    expect(none.withTypes({}).isEmpty, isTrue);

    final one = none.withTypes({'lake'});
    expect(one.typeKey, 'lake');
    expect(one.typeKeys, isNull);
    expect(one.activeTypes, {'lake'});

    final two = one.withTypes({'lake', 'waterfall'});
    expect(two.typeKey, isNull);
    expect(two.typeKeys, {'lake', 'waterfall'});
    expect(two.typeKeysLabel, 'Waterfalls, Lakes');

    final many = two.withTypes({'lake', 'waterfall', 'hike', 'forest'});
    expect(many.typeKeysLabel, 'Waterfalls, Hikes, +2');

    final back = two.withTypes({'waterfall'});
    expect(back.typeKey, 'waterfall');
    expect(back.typeKeys, isNull);
  });

  test('the filter button counts the picked type', () {
    expect(const ExploreFilters(typeKey: 'lake').activeCount, 1);
    expect(const ExploreFilters(typeKey: 'lake', maxKm: 25).activeCount, 2);
    expect(const ExploreFilters.none().activeCount, 0);
  });

  testWidgets('the sheet lists place types and returns the one picked', (
    tester,
  ) async {
    final result = await _open(
      tester,
      act: () async {
        expect(find.text('TYPE'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
        await tester.tap(find.text('Lakes'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Show 1'));
        await tester.pumpAndSettle();
      },
    );
    expect(result?.typeKey, 'lake');
  });

  testWidgets('only the first eight types show until Show all', (tester) async {
    await _open(
      tester,
      types: _manyTypes,
      act: () async {
        expect(find.text(PlaceType.all[7].pluralLabel), findsOneWidget);
        expect(find.text(PlaceType.all[8].pluralLabel), findsNothing);
        expect(find.text('Show all 10'), findsOneWidget);

        await tester.tap(find.text('Show all 10'));
        await tester.pumpAndSettle();
        expect(find.text(PlaceType.all[9].pluralLabel), findsOneWidget);
        expect(find.text('Show less'), findsOneWidget);

        await tester.tap(find.text('Show less'));
        await tester.pumpAndSettle();
        expect(find.text(PlaceType.all[8].pluralLabel), findsNothing);
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('a picked type is never left hidden', (tester) async {
    final hidden = PlaceType.all[9];
    await _open(
      tester,
      types: _manyTypes,
      initial: ExploreFilters(typeKey: hidden.key),
      act: () async {
        expect(find.text(hidden.pluralLabel), findsOneWidget);
        expect(find.text('Show less'), findsOneWidget);
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('the button stays in view and the sheet is capped', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _open(
      tester,
      types: _manyTypes,
      act: () async {
        await tester.tap(find.text('Show all 10'));
        await tester.pumpAndSettle();
        final button = tester.getRect(find.byType(FilledButton));
        expect(button.bottom, lessThanOrEqualTo(600));
        expect(find.text('Filters'), findsOneWidget);
        final sheetTop = tester.getTopLeft(find.text('Filters')).dy;
        expect(sheetTop, greaterThanOrEqualTo(600 * 0.15));

        // Scrolling the filters leaves the button where it is.
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byType(FilledButton)), button);
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('several types can be on at once', (tester) async {
    final result = await _open(
      tester,
      act: () async {
        await tester.tap(find.text('Lakes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Waterfalls'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Show 1'));
        await tester.pumpAndSettle();
      },
    );
    expect(result?.typeKey, isNull);
    expect(result?.typeKeys, {'lake', 'waterfall'});
    expect(result?.typeKeysLabel, 'Waterfalls, Lakes');
    expect(result?.activeCount, 1);
  });

  testWidgets('tapping a picked type again turns just that one off', (
    tester,
  ) async {
    final result = await _open(
      tester,
      act: () async {
        await tester.tap(find.text('Lakes'));
        await tester.tap(find.text('Waterfalls'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lakes'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Show 1'));
        await tester.pumpAndSettle();
      },
    );
    expect(result?.typeKey, 'waterfall');
    expect(result?.typeKeys, isNull);
  });

  testWidgets('tapping the chosen type again, or All, clears it', (
    tester,
  ) async {
    final result = await _open(
      tester,
      initial: const ExploreFilters(typeKey: 'lake'),
      act: () async {
        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Show 3'));
        await tester.pumpAndSettle();
      },
    );
    expect(result?.typeKey, isNull);
  });

  testWidgets('Reset clears the type too', (tester) async {
    final result = await _open(
      tester,
      initial: const ExploreFilters(typeKey: 'lake'),
      act: () async {
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Show 3'));
        await tester.pumpAndSettle();
      },
    );
    expect(result?.isEmpty, isTrue);
  });

  testWidgets('the dock keeps search and filter, with no type pills', (
    tester,
  ) async {
    var filterTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExploreFieldGuideDock(
            mode: ExploreViewMode.places,
            filterCount: 2,
            query: '',
            onSearchChanged: (_) {},
            onFilterTap: () => filterTaps++,
          ),
        ),
      ),
    );
    expect(find.text('Search places or counties'), findsOneWidget);
    expect(find.text('Waterfalls'), findsNothing);
    expect(find.text('All'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.byTooltip('Filter places'));
    expect(filterTaps, 1);
  });
}
