import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/map_place.dart';
import '../../../design/app_colors.dart';
import '../application/saved_trips_providers.dart';
import '../application/trip_plan_view.dart';
import '../application/trip_planner_providers.dart';
import '../domain/trip_plan_snapshot.dart';
import '../domain/trip_route.dart';
import 'save_plan_button.dart';
import 'saved_plans_row.dart';
import 'trip_nearby_places_row.dart';
import 'trip_plan_counties.dart';
import 'trip_plan_map_card.dart';
import 'trip_plan_map_page.dart';
import 'trip_stops_list.dart';

/// Place Detail's Plan trip tab: saved plans, the road on a map, the stops,
/// places to add as stops, the counties it passes through and the
/// secondary actions. Places picked from "Add a stop" become stops: the
/// route, the stops and the counties follow them.
class TripPlanSection extends ConsumerWidget {
  const TripPlanSection({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    required this.onStart,
    this.onOpenPlace,
    this.onDirections,
  });

  final String placeId;
  final String placeName;
  final double latitude;
  final double longitude;

  /// Starts the trip through the given stops, in driving order.
  final Future<void> Function(BuildContext context, List<MapPlace> stops)
  onStart;
  final void Function(BuildContext context, String placeId)? onOpenPlace;

  /// Opens turn-by-turn directions through [stops], in driving order.
  final Future<void> Function(List<MapPlace> stops)? onDirections;

  /// The stops as the list shows them: the user's order straight away when
  /// they set it; else the planned order, with any just-added stop last
  /// until the new route arrives.
  List<MapPlace> _listed(
    List<MapPlace> picked,
    TripPlanSnapshot snapshot, {
    required bool custom,
  }) {
    final plan = snapshot.plan;
    if (custom || plan == null) return picked;
    final ids = {for (final p in picked) p.id};
    final planned = [
      for (final s in plan.stops)
        if (ids.contains(s.id)) s,
    ];
    final plannedIds = {for (final p in planned) p.id};
    return [
      ...planned,
      for (final p in picked)
        if (!plannedIds.contains(p.id)) p,
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(
      tripPlanViewProvider(placeId, latitude, longitude),
    );
    final claimed = ref.watch(claimedCountyCodesProvider).value ?? <int>{};
    final custom = ref.watch(tripCustomOrderProvider(placeId));
    final picked = ref.watch(tripStopsProvider(placeId));
    final canSave =
        picked.isNotEmpty && ref.watch(savedTripsRepositoryProvider) != null;
    final plan = snapshot.plan;
    final stops = _listed(picked, snapshot, custom: custom);
    final ready = snapshot.status == TripPlanStatus.ready && plan != null;
    final customNotifier = ref.read(tripCustomOrderProvider(placeId).notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SavedPlansRow(placeId: placeId),
        TripPlanMapCard(
          snapshot: snapshot,
          destination: TripRoutePoint(latitude, longitude),
          onExpand: () => TripPlanMapPage.open(
            context,
            placeId: placeId,
            placeName: placeName,
            latitude: latitude,
            longitude: longitude,
            onStart: onStart,
          ),
          onTurnOnLocation: () => ref.invalidate(tripOriginProvider),
          onRetry: () => ref
            ..invalidate(tripPlanProvider)
            ..invalidate(tripOriginProvider),
        ),
        const SizedBox(height: 22),
        TripStopsList(
          stops: stops,
          destinationName: placeName,
          destLat: latitude,
          destLng: longitude,
          custom: custom,
          extraMeters: plan?.extraMeters ?? 0,
          onRemove: (id) =>
              ref.read(tripStopsProvider(placeId).notifier).remove(id),
          onReorder: (ordered) {
            ref.read(tripStopsProvider(placeId).notifier).setOrder(ordered);
            customNotifier.set(custom: true);
          },
          onAutoOrder: () => customNotifier.set(custom: false),
        ),
        const SizedBox(height: 22),
        TripNearbyPlacesRow(
          placeId: placeId,
          latitude: latitude,
          longitude: longitude,
          claimed: claimed,
          routeCounties: {...?plan?.countyCodes},
          onOpenPlace: onOpenPlace,
        ),
        if (ready && plan.countyCodes.isNotEmpty) ...[
          const SizedBox(height: 22),
          TripPlanCounties(
            countyCodes: plan.countyCodes,
            claimedCountyCodes: claimed,
          ),
        ],
        if (onDirections != null) ...[
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => unawaited(
                      onDirections!(plan == null ? stops : plan.stops),
                    ),
                    icon: const Icon(Icons.directions_outlined, size: 18),
                    label: const Text('Directions only'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.buttonForeground,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ),
              if (canSave) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: SavePlanButton(placeId: placeId, placeName: placeName),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
