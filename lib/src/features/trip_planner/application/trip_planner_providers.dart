import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/map_place.dart';
import '../../../core/services/app_config_provider.dart';
import '../../../core/services/app_current_location.dart';
import '../../../core/services/supabase_client_provider.dart';
import '../../badges/application/badges_providers.dart';
import '../data/county_shapes_source.dart';
import '../data/mapbox_directions_client.dart';
import '../data/places_repository.dart';
import '../domain/county_crossings.dart';
import '../domain/county_shape.dart';
import '../domain/nearby_places.dart';
import '../domain/saved_trip.dart';
import '../domain/trip_plan.dart';
import '../domain/trip_route.dart';
import '../domain/trip_stop_order.dart';

part 'trip_planner_providers.g.dart';

@riverpod
MapboxDirectionsClient directionsClient(Ref ref) {
  final client = MapboxDirectionsClient(
    accessToken: ref.watch(appConfigProvider).mapboxAccessToken,
  );
  ref.onDispose(client.close);
  return client;
}

/// The county boundaries, parsed once.
@Riverpod(keepAlive: true)
Future<List<CountyShape>> countyShapes(Ref ref) =>
    const CountyShapesSource().load();

/// Every place the planner can suggest, read once and kept.
@Riverpod(keepAlive: true)
Future<List<MapPlace>> placesCatalog(Ref ref) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const [];
  return PlacesRepository(client).all();
}

/// Where the user is, read once for the page and shared by the plan.
@riverpod
Future<TripRoutePoint?> tripOrigin(Ref ref) async {
  final here = await AppCurrentLocation.read();
  return here == null ? null : TripRoutePoint(here.latitude, here.longitude);
}

/// The places picked as stops on the way to [placeId], in the order they
/// were picked. The planner orders them for the road.
@riverpod
class TripStops extends _$TripStops {
  @override
  List<MapPlace> build(String placeId) => const [];

  /// Adds [place], or removes it if already a stop. False when the trip is
  /// already full.
  bool toggle(MapPlace place) {
    if (state.any((p) => p.id == place.id)) {
      state = [
        for (final p in state)
          if (p.id != place.id) p,
      ];
      return true;
    }
    if (state.length >= TripStopOrder.maxStops) return false;
    state = [...state, place];
    return true;
  }

  /// Replaces the stops with [ordered], the order the user chose.
  void setOrder(List<MapPlace> ordered) => state = ordered;

  void remove(String id) => state = [
    for (final p in state)
      if (p.id != id) p,
  ];
}

/// True once the user has set the stop order themselves; false while the
/// planner picks the shortest order.
@riverpod
class TripCustomOrder extends _$TripCustomOrder {
  @override
  bool build(String placeId) => false;

  // The state is a plain flag; a setter keeps the call sites readable.
  // ignore: use_setters_to_change_properties
  void set({required bool custom}) => state = custom;
}

/// The `stopIds` argument of [tripPlanProvider] for [stops]. In the
/// planner's order the ids are sorted, so picking in a different order asks
/// for the same route; in the user's own order they keep it, marked "!".
String tripStopKey(List<MapPlace> stops, {bool custom = false}) =>
    SavedTrip.keyFor([for (final s in stops) s.id], custom: custom);

/// The driving route from where the user is, through [stopIds] (comma
/// separated place ids, in driving order when it starts with "!"; else
/// the planner puts them in driving order), to a
/// place, and the counties it passes through. Fails with a
/// [TripRouteException] that is fit to show.
@riverpod
Future<TripPlan> tripPlan(
  Ref ref,
  double destLat,
  double destLng,
  String stopIds,
) async {
  if (ref.watch(appConfigProvider).mapboxAccessToken.isEmpty) {
    throw const TripRouteException('Route planning is not set up here.');
  }
  final origin = await ref.watch(tripOriginProvider.future);
  if (origin == null) {
    throw const TripRouteException(
      'Turn on location to plan the route.',
      locationOff: true,
    );
  }
  var stops = <MapPlace>[];
  var extra = 0.0;
  if (stopIds.isNotEmpty) {
    final custom = stopIds.startsWith('!');
    final byId = {
      for (final p in await ref.watch(placesCatalogProvider.future)) p.id: p,
    };
    final picked = [
      for (final id in stopIds.replaceFirst('!', '').split(','))
        ?byId[id],
    ];
    if (custom) {
      stops = picked;
      extra = TripStopOrder.extraMeters(
        fromLat: origin.lat,
        fromLng: origin.lng,
        toLat: destLat,
        toLng: destLng,
        chosen: picked,
      );
    } else {
      stops = TripStopOrder.order(
        fromLat: origin.lat,
        fromLng: origin.lng,
        toLat: destLat,
        toLng: destLng,
        stops: picked,
      );
    }
  }
  final route = await ref
      .watch(directionsClientProvider)
      .drive(
        fromLat: origin.lat,
        fromLng: origin.lng,
        toLat: destLat,
        toLng: destLng,
        via: [for (final s in stops) TripRoutePoint(s.lat, s.lng)],
      );
  final shapes = await ref.watch(countyShapesProvider.future);
  return TripPlan(
    route: route,
    countyCodes: CountyCrossings.along(route.points, shapes),
    stops: stops,
    extraMeters: extra,
  );
}

/// The counties the signed-in user has claimed. Empty when the badge
/// collection cannot be read, so every county then reads as new.
@riverpod
Future<Set<int>> claimedCountyCodes(Ref ref) async {
  try {
    final collection = await ref.watch(badgeCollectionProvider.future);
    return {
      for (final badge in collection.badges)
        if (badge.isEarned) badge.county.code,
    };
  } on Object {
    return <int>{};
  }
}

/// The places nearest a place, for "Also near here". Empty without Supabase.
@riverpod
Future<List<NearbyPlace>> nearbyPlaces(
  Ref ref,
  String placeId,
  double lat,
  double lng,
) async {
  final places = await ref.watch(placesCatalogProvider.future);
  return NearbyPlaces.near(
    lat: lat,
    lng: lng,
    places: places,
    exceptId: placeId,
  );
}
