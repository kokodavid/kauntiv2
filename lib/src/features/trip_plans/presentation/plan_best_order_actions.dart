import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_floating_toast.dart';
import '../application/plan_best_order.dart';
import '../domain/plan_day.dart';
import '../domain/trip_plan.dart';
import 'plan_edit_sheets.dart';
import 'plan_pro_sheet.dart';

/// "Best order" on a day: Free sees the Pro sheet; Pro gets the stops put
/// in a short driving order, with Undo.
class PlanBestOrderActions {
  PlanBestOrderActions(this.context, this.ref, this.plan);

  final BuildContext context;
  final WidgetRef ref;
  final TripPlan plan;

  Future<void> run(PlanDay day) async {
    if (!plan.limits.bestOrder) {
      await showPlanProSheet(context, trigger: PlanProTrigger.bestOrder);
      return;
    }
    showAppToast(
      context,
      variant: AppToastVariant.neutral,
      title: 'Working out the best order…',
    );
    final service = ref.read(planBestOrderProvider);
    final result = await service.run(plan, day);
    if (!context.mounted) return;
    final failure = result.failure;
    if (failure != null) {
      reportPlanFailure(context, failure);
      return;
    }
    if (!result.changed) {
      showAppToast(
        context,
        variant: AppToastVariant.neutral,
        title: '${day.displayTitle} is already in a good order',
      );
      return;
    }
    showAppToast(
      context,
      variant: AppToastVariant.success,
      title: '${day.displayTitle} reordered',
      actionLabel: 'Undo',
      onAction: () => unawaited(
        service.restore(plan.id, day.id, result.previous),
      ),
    );
  }
}
