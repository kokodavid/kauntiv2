import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_day_recording.dart';
import '../domain/plan_labels.dart';
import '../domain/plan_route.dart';
import 'plan_stop_menu.dart';

/// What a person who can edit may do on a day. Null on the section means
/// read only (viewer, or offline).
class PlanDayActions {
  const PlanDayActions({
    required this.onStop,
    required this.onRenameDay,
    required this.canMoveStopsToDay,
    required this.onAddPlaces,
    required this.onOvernight,
    this.hasOvernight = false,
    this.onRemoveDay,
    this.onAddFromPlaces,
    this.onBestOrder,
    this.bestOrderIsPro = false,
  });

  final void Function(int index, PlanStopAction action) onStop;
  final VoidCallback onRenameDay;

  /// Opens Add places for this day.
  final VoidCallback onAddPlaces;

  /// Opens the "where do you stay tonight" sheet.
  final VoidCallback onOvernight;
  final bool hasOvernight;

  /// Null when this is the plan's only day.
  final VoidCallback? onRemoveDay;

  /// Null when Places to visit is empty.
  final VoidCallback? onAddFromPlaces;
  final bool canMoveStopsToDay;

  /// Null when the day has fewer than 3 stops.
  final VoidCallback? onBestOrder;

  /// Free: the button carries the Pro tag and opens the Pro sheet.
  final bool bestOrderIsPro;
}

/// Whether the road for the day is loading, worked out, or failed. The
/// stops stay whatever happens here.
class PlanRouteLine extends StatelessWidget {
  const PlanRouteLine({super.key, required this.route, required this.onRetry});

  final AsyncValue<PlanRoute?> route;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (route.isLoading && !route.hasValue) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          key: const ValueKey('route-skeleton'),
          height: 14,
          width: 180,
          decoration: BoxDecoration(
            color: AppColors.lockedFill,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      );
    }
    if (route.hasError) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 6),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                "Couldn't work out the road. Your stops are safe.",
                style: AppTypeScale.small,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final worked = route.value;
    if (worked == null) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        '${PlanLabels.drive(worked.durationS)} drive · '
        '${PlanLabels.distance(worked.distanceM)}',
        style: AppTypeScale.body.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.mutedForeground,
        ),
      ),
    );
  }
}

/// "Recorded on Sat 14 Nov · Watch replay" (design 7c).
class PlanRecordedRow extends StatelessWidget {
  const PlanRecordedRow({
    super.key,
    required this.recording,
    this.onWatchReplay,
  });

  final PlanDayRecording recording;
  final VoidCallback? onWatchReplay;

  @override
  Widget build(BuildContext context) {
    final at = recording.startedAt?.toLocal();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.successTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.legendHome),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              at == null ? 'Recorded' : 'Recorded on ${PlanLabels.day(at)}',
              style: AppTypeScale.small,
            ),
          ),
          if (onWatchReplay != null)
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              onPressed: onWatchReplay,
              child: const Text('Watch replay'),
            ),
        ],
      ),
    );
  }
}
