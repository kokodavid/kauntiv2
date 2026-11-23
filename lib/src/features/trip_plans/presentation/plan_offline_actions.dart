import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_floating_toast.dart';
import '../application/plan_offline_copy.dart';
import '../domain/trip_plan.dart';
import 'plan_edit_sheets.dart';
import 'plan_menu.dart';
import 'plan_pro_sheet.dart';

/// "Keep offline" and "Remove offline copy" from the plan menu. Free sees
/// the Pro sheet; Pro saves the map and pictures on this phone.
class PlanOfflineActions {
  PlanOfflineActions(this.context, this.ref, this.plan);

  final BuildContext context;
  final WidgetRef ref;
  final TripPlan plan;

  Future<void> handle(PlanMenuAction action) async {
    final copy = ref.read(planOfflineCopyProvider(plan.id).notifier);
    switch (action) {
      case PlanMenuAction.keepOffline:
        if (!plan.limits.offlineCopy) {
          await showPlanProSheet(context, trigger: PlanProTrigger.offlineCopy);
          return;
        }
        showAppToast(
          context,
          variant: AppToastVariant.neutral,
          title: 'Saving this plan offline…',
          message: 'You can keep using the app meanwhile.',
        );
        final failure = await copy.download(plan);
        if (!context.mounted) return;
        if (failure != null) {
          reportPlanFailure(context, failure);
          return;
        }
        showAppToast(
          context,
          variant: AppToastVariant.success,
          title: 'Saved offline',
          message: 'The map and pictures open without signal.',
        );
      case PlanMenuAction.removeOffline:
        await copy.remove();
        if (!context.mounted) return;
        showAppToast(
          context,
          variant: AppToastVariant.neutral,
          title: 'Offline copy removed',
        );
      default:
        break;
    }
  }
}
