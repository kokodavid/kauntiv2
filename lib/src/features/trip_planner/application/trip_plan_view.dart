import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/nearby_places.dart';
import '../domain/trip_plan.dart';
import '../domain/trip_plan_snapshot.dart';
import '../domain/trip_route.dart';
import 'trip_planner_providers.dart';

part 'trip_plan_view.g.dart';

/// The stops key the route is planned for. It follows the picked stops and
/// their order once they settle, so a run of taps asks Mapbox once.
@riverpod
class TripPlanKey extends _$TripPlanKey {
  static const _settle = Duration(milliseconds: 600);

  Timer? _timer;

  @override
  String build(String placeId) {
    ref
      ..onDispose(() => _timer?.cancel())
      ..listen(tripStopsProvider(placeId), (_, _) => _changed())
      ..listen(tripCustomOrderProvider(placeId), (_, _) => _changed());
    return _current;
  }

  String get _current => tripStopKey(
    ref.read(tripStopsProvider(placeId)),
    custom: ref.read(tripCustomOrderProvider(placeId)),
  );

  void _changed() {
    _timer?.cancel();
    final key = _current;
    if (key == state) return;
    _timer = Timer(_settle, () => state = key);
  }
}

/// The plan as the Plan trip tab, the full-screen map and the Start bar
/// show it. Keeps the last route on screen while the next one is planned.
@riverpod
class TripPlanView extends _$TripPlanView {
  TripPlan? _last;

  @override
  TripPlanSnapshot build(String placeId, double lat, double lng) {
    final key = ref.watch(tripPlanKeyProvider(placeId));
    final plan = ref.watch(tripPlanProvider(lat, lng, key));
    final origin = ref.watch(tripOriginProvider).value;
    final straight = origin == null
        ? null
        : NearbyPlaces.metres(origin.lat, origin.lng, lat, lng);
    final loaded = plan.value;
    if (loaded != null) {
      _last = loaded;
      return TripPlanSnapshot(
        status: TripPlanStatus.ready,
        plan: loaded,
        origin: origin,
        straightMeters: straight,
      );
    }
    final error = plan.error;
    if (error != null) {
      final off = error is TripRouteException && error.locationOff;
      return TripPlanSnapshot(
        status: off ? TripPlanStatus.noLocation : TripPlanStatus.noRoute,
        message: error is TripRouteException
            ? error.message
            : "Couldn't plan the route.",
        origin: origin,
        straightMeters: straight,
      );
    }
    final previous = _last;
    return TripPlanSnapshot(
      status: previous == null ? TripPlanStatus.planning : TripPlanStatus.ready,
      plan: previous,
      updating: previous != null,
      origin: origin,
      straightMeters: straight,
    );
  }
}
