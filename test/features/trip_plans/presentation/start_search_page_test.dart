import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/create_plan_controller.dart';
import 'package:kaunti47_v2/src/features/trip_plans/application/plan_place_search.dart';
import 'package:kaunti47_v2/src/features/trip_plans/data/plan_place_search_client.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_place_suggestion.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/start_search_page.dart';

class _FakeSearch implements PlanPlaceSearchClient {
  final queries = <String>[];
  bool fail = false;

  @override
  Future<List<PlanPlaceSuggestion>> search(
    String query, {
    double? nearLat,
    double? nearLng,
  }) async {
    queries.add(query);
    if (fail) throw const PlanPlaceSearchFailure('x');
    if (query.startsWith('zzz')) return const [];
    return const [
      PlanPlaceSuggestion(
        name: 'Total Energies Westlands',
        address: 'Westlands, Nairobi, Kenya',
        lat: -1.2635,
        lng: 36.8047,
      ),
    ];
  }
}

void main() {
  late _FakeSearch search;
  PlanStart? picked;

  setUp(() {
    search = _FakeSearch();
    picked = null;
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planPlaceSearchClientProvider.overrideWithValue(search),
          planCurrentLocationProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  picked = await showStartSearchPage(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('shows suggestions as the user types and returns the pick', (
    tester,
  ) async {
    await open(tester);
    expect(find.textContaining('at least 3 letters'), findsOneWidget);
    await type(tester, 'total west');
    expect(find.text('Total Energies Westlands'), findsOneWidget);
    expect(find.text('Westlands, Nairobi, Kenya'), findsOneWidget);
    await tester.tap(find.text('Total Energies Westlands'));
    await tester.pumpAndSettle();
    expect(picked?.kind, PlanStartKind.point);
    expect(picked?.lat, -1.2635);
  });

  testWidgets('fewer than 3 letters asks nothing', (tester) async {
    await open(tester);
    await type(tester, 'to');
    expect(search.queries, isEmpty);
  });

  testWidgets('no match and a failed search each say so', (tester) async {
    await open(tester);
    await type(tester, 'zzzz');
    expect(find.textContaining('No match'), findsOneWidget);
    search.fail = true;
    await type(tester, 'westlands');
    expect(find.textContaining("Couldn't search"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
