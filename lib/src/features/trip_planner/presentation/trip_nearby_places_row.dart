import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/trip_planner_providers.dart';
import '../domain/trip_stop_order.dart';
import 'trip_nearby_card.dart';

/// "ADD A STOP · ALSO NEAR HERE": the places closest to the one being
/// planned. Tapping a card adds it as a stop (or takes it off); a long
/// press offers "View place". With four stops the rest dim. Hides itself
/// while loading and on failure.
class TripNearbyPlacesRow extends ConsumerWidget {
  const TripNearbyPlacesRow({
    super.key,
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.claimed,
    required this.routeCounties,
    this.onOpenPlace,
  });

  final String placeId;
  final double latitude;
  final double longitude;
  final Set<int> claimed;

  /// The counties the planned road already passes through.
  final Set<int> routeCounties;
  final void Function(BuildContext context, String placeId)? onOpenPlace;

  static const _rowHeight = 148.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearby = ref
        .watch(nearbyPlacesProvider(placeId, latitude, longitude))
        .value;
    if (nearby == null) return const SizedBox.shrink();
    final pickedIds = {
      for (final p in ref.watch(tripStopsProvider(placeId))) p.id,
    };
    final full = pickedIds.length >= TripStopOrder.maxStops;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADD A STOP · ALSO NEAR HERE',
          style: AppTypeScale.sectionLabel.copyWith(color: AppColors.accent),
        ),
        const SizedBox(height: 10),
        if (nearby.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'No other places near here yet. You can still go straight '
              'there.',
              style: AppTypeScale.body,
            ),
          )
        else ...[
          SizedBox(
            height: _rowHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: nearby.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final entry = nearby[index];
                final id = entry.place.id;
                final added = pickedIds.contains(id);
                return TripNearbyCard(
                  entry: entry,
                  added: added,
                  disabled: full && !added,
                  note: _note(entry.place.countyCode, added),
                  onToggle: () => ref
                      .read(tripStopsProvider(placeId).notifier)
                      .toggle(entry.place),
                  onView: onOpenPlace == null
                      ? null
                      : () => onOpenPlace!(context, id),
                );
              },
            ),
          ),
          if (full)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '${TripStopOrder.maxStops} of ${TripStopOrder.maxStops} '
                'stops. Remove one to add another.',
                style: AppTypeScale.small,
              ),
            ),
        ],
      ],
    );
  }

  /// A short line on what the stop adds, never a promise: badges come from
  /// where the Trip actually goes.
  TripNearbyNote _note(int countyCode, bool added) {
    if (added) return TripNearbyNote.onTrip;
    if (claimed.contains(countyCode)) return TripNearbyNote.none;
    return routeCounties.contains(countyCode)
        ? TripNearbyNote.alreadyOnWay
        : TripNearbyNote.newCounty;
  }
}
