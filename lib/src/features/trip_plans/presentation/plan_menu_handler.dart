import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/trip_plan.dart';
import 'plan_menu.dart';
import 'plan_offline_actions.dart';
import 'plan_screen_actions.dart';
import 'plan_share_actions.dart';

/// Sends a plan-menu choice to whoever handles it: editing, sharing or
/// offline copy.
class PlanMenuHandler {
  PlanMenuHandler(
    BuildContext context,
    WidgetRef ref,
    TripPlan plan, {
    this.edit,
    VoidCallback? onGone,
  }) : _share = PlanShareActions(context, ref, plan, onGone: onGone),
       _offline = PlanOfflineActions(context, ref, plan);

  /// Null when the plan can't be edited (view-only).
  final PlanScreenActions? edit;
  final PlanShareActions _share;
  final PlanOfflineActions _offline;

  Future<void> handle(PlanMenuAction action) {
    if (action.isSharing) return _share.handle(action);
    if (action.isOffline) return _offline.handle(action);
    return edit?.planMenu(action) ?? Future.value();
  }
}
