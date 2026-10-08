import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../application/saved_trips_providers.dart';
import '../application/trip_planner_providers.dart';
import '../domain/saved_trip.dart';
import 'plan_name_dialog.dart';

/// "Save plan": keeps the destination and the picked stops (in the order
/// they are being used) so the trip does not have to be built again. Reads
/// "Saved" once this exact plan is saved.
class SavePlanButton extends ConsumerStatefulWidget {
  const SavePlanButton({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  final String placeId;
  final String placeName;

  @override
  ConsumerState<SavePlanButton> createState() => _SavePlanButtonState();
}

class _SavePlanButtonState extends ConsumerState<SavePlanButton> {
  bool _saving = false;

  Future<void> _save({
    required List<String> ids,
    required bool custom,
  }) async {
    final repository = ref.read(savedTripsRepositoryProvider);
    if (repository == null || _saving) return;
    final name = await showPlanNameDialog(
      context,
      title: 'Save this plan',
      initial: SavedTrip.suggestName(widget.placeName, ids.length),
    );
    if (name == null || !mounted) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      await repository.save(
        name: name,
        destinationPlaceId: widget.placeId,
        stopPlaceIds: ids,
        customOrder: custom,
      );
      ref.invalidate(savedTripsForPlaceProvider(widget.placeId));
      message = 'Plan saved.';
    } on SavedTripExists {
      message = 'You have already saved this plan.';
    } on SavedTripsFull {
      message = 'You can save up to 50 plans. Delete one to save another.';
    } on Object {
      message = "Couldn't save the plan. Try again.";
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final picked = ref.watch(tripStopsProvider(widget.placeId));
    // A custom order only means something with two or more stops.
    final custom =
        ref.watch(tripCustomOrderProvider(widget.placeId)) && picked.length > 1;
    final ids = [for (final p in picked) p.id];
    final saved =
        ref.watch(savedTripsForPlaceProvider(widget.placeId)).value ?? [];
    final key = SavedTrip.keyFor(ids, custom: custom);
    final already = saved.any((plan) => plan.key == key);
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: already || _saving
            ? null
            : () => unawaited(
                _save(
                  ids: custom ? ids : ([...ids]..sort()),
                  custom: custom,
                ),
              ),
        icon: Icon(
          already ? Icons.bookmark_added_outlined : Icons.bookmark_add_outlined,
          size: 18,
        ),
        label: Text(already ? 'Saved' : 'Save plan'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.buttonForeground,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
