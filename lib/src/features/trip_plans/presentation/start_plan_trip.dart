import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_floating_toast.dart';
import '../application/trip_plans_providers.dart';
import '../domain/plan_limits.dart';
import '../domain/trip_plan.dart';
import 'create_plan_sheet.dart';
import 'plan_pro_sheet.dart';
import 'planned_view.dart';
import 'start_search_page.dart';

/// "Plan a trip": the create sheet, or the Pro sheet when a Free user
/// already has their 3 upcoming plans (design 7a). Opens the new plan when
/// [onOpenPlan] is given.
Future<void> startPlanTrip(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onSeePro,
  OpenTripPlan? onOpenPlan,
  ChoosePlanStart? onChoosePlace,
  ChoosePlanStart? onPickOnMap,
  String? firstPlaceId,
}) async {
  PlanLimits limits;
  try {
    limits = await ref.read(myPlanLimitsProvider.future);
  } on Object {
    limits = PlanLimits.free;
  }
  if (!context.mounted) return;
  if (!limits.canCreatePlan) {
    await showPlanProSheet(
      context,
      trigger: PlanProTrigger.upcomingPlans,
      onSeePro: onSeePro,
    );
    return;
  }
  final id = await showCreatePlanSheet(
    context,
    limits: limits,
    onSeePro: onSeePro,
    onChoosePlace: onChoosePlace ?? _choosePlace,
    onPickOnMap: onPickOnMap,
    firstPlaceId: firstPlaceId,
  );
  if (id == null || !context.mounted) return;
  if (onOpenPlan != null) {
    onOpenPlan(context, id);
  } else {
    showAppToast(
      context,
      variant: AppToastVariant.success,
      title: 'Plan created',
      message: 'It\'s in Planned, under Upcoming.',
    );
  }
}

/// "Choose a place" for where Day 1 starts: a search for any real spot.
Future<PlanStart?> _choosePlace(BuildContext context) =>
    showStartSearchPage(context);
