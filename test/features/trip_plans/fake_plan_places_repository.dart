import 'package:kaunti47_v2/src/features/trip_plans/data/plan_places_repository.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_place.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_place_facets.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_place_query.dart';

/// Places from a fixed list, filtered the way the server would.
class FakePlanPlacesRepository implements PlanPlacesRepository {
  FakePlanPlacesRepository(this.places);

  final List<PlanPlace> places;
  final queries = <PlanPlaceQuery>[];

  @override
  Future<List<PlanPlace>> search(PlanPlaceQuery query, {int limit = 30}) async {
    queries.add(query);
    final text = query.text.trim().toLowerCase();
    return [
      for (final place in places)
        if ((text.length < 2 || place.name.toLowerCase().contains(text)) &&
            (query.countyCode == null ||
                place.countyCode == query.countyCode) &&
            (query.type == null || place.type == query.type))
          place,
    ];
  }

  @override
  Future<PlanPlaceFacets> facets() async => PlanPlaceFacets(
    types: {for (final p in places) p.type},
    counties: {for (final p in places) p.countyCode},
  );
}
