import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/saved_trips_providers.dart';
import '../application/trip_planner_providers.dart';
import '../domain/saved_trip.dart';
import 'saved_plan_actions.dart';
import 'saved_plan_manage.dart';

/// "YOUR SAVED PLANS" to this place. Tapping one fills in its stops and
/// order and the route follows; the menu renames or deletes it. Hidden
/// when there are none.
class SavedPlansRow extends ConsumerWidget {
  const SavedPlansRow({super.key, required this.placeId});

  final String placeId;

  Future<void> _apply(BuildContext context, WidgetRef ref, SavedTrip plan) =>
      applySavedTrip(context, ref, placeId, plan);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(savedTripsForPlaceProvider(placeId)).value;
    if (plans == null || plans.isEmpty) return const SizedBox.shrink();
    final picked = ref.watch(tripStopsProvider(placeId));
    final custom =
        ref.watch(tripCustomOrderProvider(placeId)) && picked.length > 1;
    final currentKey = SavedTrip.keyFor([
      for (final p in picked) p.id,
    ], custom: custom);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR PLANS',
            style: AppTypeScale.sectionLabel.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: plans.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final plan = plans[index];
                return _PlanChip(
                  plan: plan,
                  selected: plan.key == currentKey,
                  onTap: () => unawaited(_apply(context, ref, plan)),
                  onRename: () => unawaited(SavedPlanManage.rename(context, ref, plan)),
                  onDelete: () => unawaited(SavedPlanManage.delete(context, ref, plan)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({
    required this.plan,
    required this.selected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final SavedTrip plan;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final stops = plan.stopPlaceIds.length;
    final ink = selected ? Colors.white : AppColors.foreground;
    final soft = selected
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.mutedForeground;
    return Material(
      color: selected ? AppColors.accent : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.cardBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: plan.name,
                        style: AppTypeScale.itemTitle.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: stops == 0
                            ? '  Direct'
                            : '  $stops ${stops == 1 ? 'stop' : 'stops'}',
                        style: AppTypeScale.small.copyWith(color: soft),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<VoidCallback>(
                tooltip: 'Plan options',
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_horiz, size: 18, color: ink),
                onSelected: (action) => action(),
                itemBuilder: (context) => [
                  PopupMenuItem(value: onRename, child: const Text('Rename')),
                  PopupMenuItem(value: onDelete, child: const Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
