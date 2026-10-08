import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/saved_trips_providers.dart';
import '../application/trip_planner_providers.dart';
import '../domain/saved_trip.dart';
import 'plan_name_dialog.dart';
import 'saved_plan_actions.dart';

/// Renames, deletes and opens saved plans; shared by the plans row on a
/// place, the Home section and the saved plans screen.
abstract final class SavedPlanManage {
  static void _refresh(WidgetRef ref, SavedTrip plan) {
    ref
      ..invalidate(savedTripsForPlaceProvider(plan.destinationPlaceId))
      ..invalidate(savedTripsAllProvider);
  }

  static Future<void> rename(
    BuildContext context,
    WidgetRef ref,
    SavedTrip plan,
  ) async {
    final name = await showPlanNameDialog(
      context,
      title: 'Rename plan',
      initial: plan.name,
    );
    if (name == null || name == plan.name || !context.mounted) return;
    await _run(context, ref, plan, () async {
      await ref.read(savedTripsRepositoryProvider)?.rename(plan.id, name);
    });
  }

  static Future<void> delete(
    BuildContext context,
    WidgetRef ref,
    SavedTrip plan,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this plan?'),
        content: Text('"${plan.name}" will be removed from your saved plans.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(context, ref, plan, () async {
      await ref.read(savedTripsRepositoryProvider)?.delete(plan.id);
    });
  }

  /// Opens the plan's destination with its stops filled in. The planner
  /// state lives only while the place page watches it, so it is held until
  /// that page has mounted.
  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    SavedTrip plan,
    void Function(BuildContext, String) openPlace,
  ) async {
    final id = plan.destinationPlaceId;
    final holds = [
      ref.listenManual(tripStopsProvider(id), (_, _) {}),
      ref.listenManual(tripCustomOrderProvider(id), (_, _) {}),
    ];
    try {
      await applySavedTrip(context, ref, id, plan);
      if (!context.mounted) return;
      openPlace(context, id);
    } finally {
      unawaited(
        Future<void>.delayed(const Duration(seconds: 3)).then((_) {
          for (final hold in holds) {
            hold.close();
          }
        }),
      );
    }
  }

  static Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    SavedTrip plan,
    Future<void> Function() change,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await change();
      _refresh(ref, plan);
    } on Object {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Couldn't update the plan. Try again.")),
        );
    }
  }
}
