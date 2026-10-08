import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/saved_trips_providers.dart';
import '../application/trip_planner_providers.dart';
import 'saved_plan_manage.dart';
import 'saved_plan_tile.dart';

/// The section's kicker, on Home and the saved plans screen.
const savedPlansLabel = 'YOUR PLANS';

/// The Home sheet's saved plans: the newest three, then "See all" for the
/// saved plans screen. Hidden until the user has saved one.
class SavedPlansHomeSection extends ConsumerWidget {
  const SavedPlansHomeSection({
    super.key,
    required this.onOpenPlace,
    required this.onSeeAll,
  });

  static const shown = 3;

  final void Function(BuildContext, String) onOpenPlace;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(savedTripsAllProvider).value;
    if (plans == null || plans.isEmpty) return const SizedBox.shrink();
    final catalog = ref.watch(placesCatalogProvider).value ?? const [];
    final byId = {for (final p in catalog) p.id: p};
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  savedPlansLabel,
                  style: AppTypeScale.sectionLabel.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
              if (plans.length > shown)
                InkWell(
                  onTap: onSeeAll,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See all ${plans.length}',
                          style: AppTypeScale.small,
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.mutedForeground,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          for (final plan in plans.take(shown)) ...[
            const SizedBox(height: 8),
            SavedPlanTile(
              plan: plan,
              destination: byId[plan.destinationPlaceId],
              onTap: () =>
                  unawaited(SavedPlanManage.open(context, ref, plan, onOpenPlace)),
            ),
          ],
        ],
      ),
    );
  }
}
