import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/saved_trips_providers.dart';
import '../application/trip_planner_providers.dart';
import 'saved_plan_manage.dart';
import 'saved_plan_tile.dart';
import 'saved_plans_home_section.dart';

/// Every saved plan, newest first; open, rename or delete each.
class SavedPlansScreen extends ConsumerWidget {
  const SavedPlansScreen({
    super.key,
    required this.onOpenPlace,
    required this.onBack,
  });

  final void Function(BuildContext, String) onOpenPlace;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(savedTripsAllProvider);
    final catalog = ref.watch(placesCatalogProvider).value ?? const [];
    final byId = {for (final p in catalog) p.id: p};
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: AppBackButton(onPressed: onBack),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    savedPlansLabel,
                    style: AppTypeScale.sectionLabel.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text('Saved plans', style: AppTypeScale.sectionTitle),
                ],
              ),
            ),
            Expanded(
              child: plans.when(
                loading: () => const Center(child: AppProgressIndicator()),
                error: (error, stack) => const SizedBox.shrink(),
                data: (list) => list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Plans you save on a place show up here.',
                          style: AppTypeScale.body,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: list.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final plan = list[index];
                          return SavedPlanTile(
                            plan: plan,
                            destination: byId[plan.destinationPlaceId],
                            onTap: () => unawaited(
                              SavedPlanManage.open(
                                context,
                                ref,
                                plan,
                                onOpenPlace,
                              ),
                            ),
                            onRename: () => unawaited(
                              SavedPlanManage.rename(context, ref, plan),
                            ),
                            onDelete: () => unawaited(
                              SavedPlanManage.delete(context, ref, plan),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
