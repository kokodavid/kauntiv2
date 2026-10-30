import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../data/plan_places_repository.dart';
import '../domain/plan_place.dart';
import '../domain/plan_place_facets.dart';
import '../domain/plan_place_query.dart';
import '../domain/plan_ref.dart';
import 'trip_plans_providers.dart';

part 'plan_places_providers.g.dart';

@riverpod
PlanPlacesRepository? planPlacesRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabasePlanPlacesRepository(client);
}

/// Places matching [query]; every place when it asks for nothing.
@riverpod
Future<List<PlanPlace>> planPlaceSearch(Ref ref, PlanPlaceQuery query) async {
  final repository = ref.watch(planPlacesRepositoryProvider);
  if (repository == null) return const [];
  return repository.search(query, limit: query.limit);
}

/// Which types and counties have places, for the filter chips.
final planPlaceFacetsProvider = FutureProvider.autoDispose<PlanPlaceFacets>((
  ref,
) async {
  final repository = ref.watch(planPlacesRepositoryProvider);
  if (repository == null) return const PlanPlaceFacets();
  return repository.facets();
});

/// The plans that already hold [placeId], for "In 2 trips". Empty when it
/// can't be read, so the button simply says "Add to trip".
@riverpod
Future<List<PlanRef>> placeTrips(Ref ref, String placeId) async {
  final repository = ref.watch(tripPlansRepositoryProvider);
  if (repository == null) return const [];
  try {
    return await repository.plansWithPlace(placeId);
  } on Object {
    return const [];
  }
}
