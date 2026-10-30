import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/plan_offline_copy.dart';
import '../application/plan_sharing.dart';
import '../domain/plan_member.dart';
import '../domain/plan_offline.dart';
import '../domain/trip_plan.dart';
import '../../../design/app_colors.dart';
import 'plan_pro_sheet.dart';

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
    final rows = <_Row>[
      if (plan.canEdit) const _Row(PlanMenuAction.rename, 'Rename'),
      if (plan.canEdit) const _Row(PlanMenuAction.dates, 'Change dates'),
      _Row(
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
      const _Row(PlanMenuAction.people, 'Members'),
      if (plan.isShared)
        _Row(
          muted ? PlanMenuAction.unmute : PlanMenuAction.mute,
          muted ? 'Unmute updates' : 'Mute updates',
        ),
      if (!isOwner || plan.isShared)
        const _Row(PlanMenuAction.leave, 'Leave plan'),
      if (isOwner) const _Row(PlanMenuAction.archive, 'Archive plan'),
      if (isOwner)
        const _Row(PlanMenuAction.delete, 'Delete plan', destructive: true),
    ];
    return PopupMenuButton<PlanMenuAction>(
      tooltip: 'Plan options',
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      padding: EdgeInsets.zero,
      offset: const Offset(0, 44),
      color: AppColors.exploreSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const SizedBox(
        width: 44,
        height: 44,
        child: Icon(Icons.more_horiz, color: AppColors.foreground),
      ),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (var i = 0; i < rows.length; i++)
          PopupMenuItem(
            value: rows[i].action,
            enabled: rows[i].enabled,
            padding: EdgeInsets.zero,
            height: 52,
            child: _RowView(rows[i], last: i == rows.length - 1),
          ),
      ],
    );
  }
}

class _Row {
  const _Row(
    this.action,
    this.label, {
    this.enabled = true,
    this.pro = false,
    this.destructive = false,
  });

  final PlanMenuAction action;
  final String label;
  final bool enabled;
  final bool pro;
  final bool destructive;
}

class _RowView extends StatelessWidget {
  const _RowView(this.row, {required this.last});

  final _Row row;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: AppColors.exploreBorder)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            row.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: row.destructive ? AppColors.danger : AppColors.foreground,
            ),
          ),
        ),
        if (row.pro) const PlanProTag(),
      ],
    ),
  );
}
