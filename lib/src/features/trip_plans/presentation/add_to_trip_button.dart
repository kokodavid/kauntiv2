import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/plan_places_providers.dart';
import '../application/trip_plans_providers.dart';
import 'add_to_trip_sheet.dart';
import 'planned_view.dart';

/// "Add to trip" on Place Detail (design 5a); "In 2 trips · Add to another"
/// when the place is already in plans. Not shown while the planner is off.
class AddToTripButton extends ConsumerWidget {
  const AddToTripButton({
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
        : count == 1
        ? 'In 1 trip · Add to another'
        : 'In $count trips · Add to another';
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          backgroundColor: AppColors.accentTint,
          foregroundColor: AppColors.accent,
          textStyle: AppTypeScale.action,
          shape: const StadiumBorder(),
        ),
        onPressed: () => unawaited(
          showAddToTrip(
            context,
            ref,
            placeId: placeId,
            placeName: placeName,
            onOpenPlan: onOpenPlan,
          ),
        ),
        icon: Icon(
          count == 0 ? Icons.add : Icons.bookmark_added_outlined,
          size: 18,
        ),
        label: Text(label),
      ),
    );
  }
}
