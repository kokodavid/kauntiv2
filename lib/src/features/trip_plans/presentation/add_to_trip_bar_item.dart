import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/place_detail_bar_button.dart';
import '../application/plan_places_providers.dart';
import '../application/trip_plans_providers.dart';
import 'add_to_trip_sheet.dart';
import 'planned_view.dart';

/// "Add to trip" as one item of Place Detail's floating action bar: the
/// compact sibling of [AddToTripButton], which drew the same action as a
/// full-width pill above the rest of the page. "In N trips" once the
/// place is already planned. Renders nothing while the trip planner is
/// switched off.
class AddToTripBarItem extends ConsumerWidget {
  const AddToTripBarItem({
    super.key,
    required this.placeId,
    required this.placeName,
    this.onOpenPlan,
  });

  final String placeId;
  final String placeName;
  final OpenTripPlan? onOpenPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(ref.watch(tripPlansEnabledProvider).value ?? false)) {
      return const SizedBox.shrink();
    }
    final count = ref.watch(placeTripsProvider(placeId)).value?.length ?? 0;
    final label = count == 0
        ? 'Add to trip'
        : 'In $count ${count == 1 ? 'trip' : 'trips'}';
    return PlaceDetailBarButton(
      icon: count == 0 ? Icons.add : Icons.bookmark_added_outlined,
      label: label,
      onPressed: () => unawaited(
        showAddToTrip(
          context,
          ref,
          placeId: placeId,
          placeName: placeName,
          onOpenPlan: onOpenPlan,
        ),
      ),
    );
  }
}
