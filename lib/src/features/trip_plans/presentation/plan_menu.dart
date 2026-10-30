import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/plan_offline_copy.dart';
import '../application/plan_sharing.dart';
import '../domain/plan_member.dart';
import '../domain/plan_offline.dart';
import '../domain/trip_plan.dart';
import 'plan_popup_menu.dart';

enum PlanMenuAction {
  rename,
  dates,
  invite,
  people,
  leave,
  mute,
  unmute,
  keepOffline,
  removeOffline,
  archive,
  unarchive,
  delete;

  /// Sharing actions are handled apart from the editing ones.
  bool get isSharing =>
      this == invite ||
      this == people ||
      this == leave ||
      this == mute ||
      this == unmute;

  bool get isOffline => this == keepOffline || this == removeOffline;
}

/// The plan's "…" (design 3g): a white card of plain rows. Editors can
/// rename and change the date, everyone sees Members, a member can leave,
/// and only the owner archives or deletes. Invite is the pill in the header.
class PlanMenu extends ConsumerWidget {
  const PlanMenu({super.key, required this.plan, required this.onSelected});

  final TripPlan plan;
  final ValueChanged<PlanMenuAction> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline =
        ref.watch(planOfflineCopyProvider(plan.id)).value ??
        PlanOfflineState.none;
    final muted = ref.watch(planMutedProvider(plan.id)).value ?? false;
    final isOwner = plan.role == PlanRole.owner;
    final rows = <PlanMenuEntry<PlanMenuAction>>[
      if (plan.canEdit) const PlanMenuEntry(PlanMenuAction.rename, 'Rename'),
      if (plan.canEdit)
        const PlanMenuEntry(PlanMenuAction.dates, 'Change dates'),
      PlanMenuEntry(
        offline.saved
            ? PlanMenuAction.removeOffline
            : PlanMenuAction.keepOffline,
        offline.saving
            ? 'Saving offline… ${((offline.progress ?? 0) * 100).round()}%'
            : offline.saved
            ? 'Remove offline copy'
            : 'Offline copy',
        enabled: !offline.saving,
        pro: !offline.saved && !plan.limits.offlineCopy,
      ),
      const PlanMenuEntry(PlanMenuAction.people, 'Members'),
      if (plan.isShared)
        PlanMenuEntry(
          muted ? PlanMenuAction.unmute : PlanMenuAction.mute,
          muted ? 'Unmute updates' : 'Mute updates',
        ),
      if (!isOwner || plan.isShared)
        const PlanMenuEntry(PlanMenuAction.leave, 'Leave plan'),
      if (isOwner)
        PlanMenuEntry(
          plan.archived ? PlanMenuAction.unarchive : PlanMenuAction.archive,
          plan.archived ? 'Unarchive plan' : 'Archive plan',
        ),
      if (isOwner)
        const PlanMenuEntry(
          PlanMenuAction.delete,
          'Delete plan',
          destructive: true,
        ),
    ];
    return PlanPopupMenu<PlanMenuAction>(
      tooltip: 'Plan options',
      entries: rows,
      onSelected: onSelected,
    );
  }
}
