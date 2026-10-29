import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_floating_toast.dart';
import '../application/plan_sharing.dart';
import '../domain/plan_member.dart';
import '../domain/trip_plan.dart';
import 'plan_edit_sheets.dart';
import 'plan_menu.dart';
import 'plan_people_sheet.dart';
import 'plan_share_sheet.dart';

/// The plan menu's sharing items: Invite people, People and Leave plan.
class PlanShareActions {
  PlanShareActions(this.context, this.ref, this.plan, {this.onGone});

  final BuildContext context;
  final WidgetRef ref;
  final TripPlan plan;

  /// Called when I'm no longer on the plan.
  final VoidCallback? onGone;

  Future<void> handle(PlanMenuAction action) async {
    switch (action) {
      case PlanMenuAction.invite:
        await showPlanShareSheet(context, plan);
      case PlanMenuAction.people:
        await showPlanPeopleSheet(context, plan);
      case PlanMenuAction.leave:
        await _leave();
      case PlanMenuAction.rename ||
          PlanMenuAction.dates ||
          PlanMenuAction.archive ||
          PlanMenuAction.delete ||
          PlanMenuAction.keepOffline ||
          PlanMenuAction.removeOffline:
        break; // handled elsewhere
    }
  }

  Future<void> _leave() async {
    final owner = plan.role == PlanRole.owner;
    final ok = await showPlanConfirm(
      context,
      title: 'Leave this plan?',
      message: owner
          ? 'It passes to the person who has edited it longest. If nobody '
                'else is on it, it is deleted.'
          : "You'll lose access. Someone can invite you again.",
      action: 'Leave',
    );
    if (!ok) return;
    final failure = await ref.read(planSharingProvider).leave(plan.id);
    if (!context.mounted) return;
    if (failure != null) {
      reportPlanFailure(context, failure);
      return;
    }
    showAppToast(context, variant: AppToastVariant.neutral, title: 'You left the plan');
    onGone?.call();
  }
}
