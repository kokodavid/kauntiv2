import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/trip_planner_providers.dart';
import '../domain/saved_trip.dart';

/// Fills in the stops and order of [plan] for the place [placeId]; the
/// route follows. Places that no longer exist are left out, with a note.
Future<void> applySavedTrip(
  BuildContext context,
  WidgetRef ref,
  String placeId,
  SavedTrip plan,
) async {
  final catalog = await ref.read(placesCatalogProvider.future);
  final byId = {for (final p in catalog) p.id: p};
  final stops = [
    for (final id in plan.stopPlaceIds) ?byId[id],
  ];
  ref.read(tripStopsProvider(placeId).notifier).setOrder(stops);
  ref
      .read(tripCustomOrderProvider(placeId).notifier)
      .set(custom: plan.customOrder && stops.length > 1);
  if (stops.length < plan.stopPlaceIds.length && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Some places in this plan are no longer available.'),
        ),
      );
  }
}
