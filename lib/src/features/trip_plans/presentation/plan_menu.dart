import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/plan_offline_copy.dart';
import '../domain/plan_member.dart';
import '../domain/plan_offline.dart';
import '../domain/trip_plan.dart';

enum PlanMenuAction {
  rename,
  dates,
  invite,
  people,
  leave,
  keepOffline,
  removeOffline,
  archive,
  delete;

  /// Sharing actions are handled apart from the editing ones.
  bool get isSharing => this == invite || this == people || this == leave;

  bool get isOffline => this == keepOffline || this == removeOffline;
}

/// The plan's "…" (design 3a). Editors can rename and change the date, the
/// owner (or a Pro editor) can invite, everyone sees People, a member can
/// leave, and only the owner archives or deletes.
class PlanMenu extends ConsumerWidget {
  const PlanMenu({super.key, required this.plan, required this.onSelected});

  final TripPlan plan;
  final ValueChanged<PlanMenuAction> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline =
        ref.watch(planOfflineCopyProvider(plan.id)).value ??
        PlanOfflineState.none;
    final isOwner = plan.role == PlanRole.owner;
    return PopupMenuButton<PlanMenuAction>(
      tooltip: 'Plan options',
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      onSelected: onSelected,
      itemBuilder: (_) => [
        if (plan.canEdit)
          const PopupMenuItem(
            value: PlanMenuAction.rename,
            child: Text('Rename plan'),
          ),
        if (plan.canEdit)
          const PopupMenuItem(
            value: PlanMenuAction.dates,
            child: Text('Change start date'),
          ),
        if (plan.canInvite)
          const PopupMenuItem(
            value: PlanMenuAction.invite,
            child: Text('Invite people'),
          ),
        const PopupMenuItem(
          value: PlanMenuAction.people,
          child: Text('People'),
        ),
        if (!isOwner || plan.isShared)
          const PopupMenuItem(
            value: PlanMenuAction.leave,
            child: Text('Leave plan'),
          ),
        PopupMenuItem(
          value: offline.saved
              ? PlanMenuAction.removeOffline
              : PlanMenuAction.keepOffline,
          enabled: !offline.saving,
          child: Text(
            offline.saving
                ? 'Saving offline… ${((offline.progress ?? 0) * 100).round()}%'
                : offline.saved
                ? 'Remove offline copy'
                : plan.limits.offlineCopy
                ? 'Keep offline'
                : 'Keep offline (Pro)',
          ),
        ),
        if (isOwner)
          const PopupMenuItem(
            value: PlanMenuAction.archive,
            child: Text('Archive plan'),
          ),
        if (isOwner)
          const PopupMenuItem(
            value: PlanMenuAction.delete,
            child: Text('Delete plan'),
          ),
      ],
    );
  }
}
