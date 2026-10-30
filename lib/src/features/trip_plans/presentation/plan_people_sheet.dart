import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../application/plan_detail.dart';
import '../application/plan_sharing.dart';
import '../domain/plan_member.dart';
import '../domain/trip_plan.dart';
import 'plan_edit_sheets.dart';
import 'plan_popup_menu.dart';
import 'plan_pro_sheet.dart';
import 'plan_share_parts.dart';
import 'plan_sheet_frame.dart';

/// Who is on the plan, and for the owner how to change that.
Future<void> showPlanPeopleSheet(BuildContext context, TripPlan plan) =>
    showPlanSheet<void>(context, (_) => PlanPeopleSheet(plan: plan));

enum _MemberAction { makeEditor, makeViewer, changeRole, handOver, remove }

class PlanPeopleSheet extends ConsumerWidget {
  const PlanPeopleSheet({super.key, required this.plan});

  final TripPlan plan;

  static String roleLabel(PlanMember m) => !m.joined
      ? 'Invited'
      : switch (m.role) {
          PlanRole.owner => 'Owner',
          PlanRole.editor => 'Can edit',
          PlanRole.viewer => 'View only',
        };

  /// "Owner · you", "Can edit · joined", "View only · invited".
  static String detail(PlanMember m, {required bool isMe}) {
    final role = switch (m.role) {
      PlanRole.owner => 'Owner',
      PlanRole.editor => 'Can edit',
      PlanRole.viewer => 'View only',
    };
    final state = isMe
        ? 'you'
        : !m.joined
        ? 'invited'
        : m.role == PlanRole.owner
        ? null
        : 'joined';
    return state == null ? role : '$role · $state';
  }

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    TripPlan current,
    PlanMember member,
    _MemberAction action,
  ) async {
    final sharing = ref.read(planSharingProvider);
    if (action == _MemberAction.changeRole) {
      await showPlanProSheet(context, trigger: PlanProTrigger.invitee);
      return;
    }
    final failure = switch (action) {
      _MemberAction.makeEditor => await sharing.setRole(
        current.id,
        member.userId,
        PlanRole.editor,
      ),
      _MemberAction.makeViewer => await sharing.setRole(
        current.id,
        member.userId,
        PlanRole.viewer,
      ),
      _MemberAction.handOver => await sharing.handOver(
        current.id,
        member.userId,
      ),
      _MemberAction.remove => await sharing.remove(current.id, member.userId),
      _MemberAction.changeRole => null,
    };
    if (failure != null && context.mounted) reportPlanFailure(context, failure);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(planDetailProvider(plan.id)).value?.plan ?? plan;
    final me = ref.watch(currentUserIdProvider)();
    final iAmOwner = current.role == PlanRole.owner;
    final members = [...current.members]
      ..sort((a, b) {
        if (a.role == PlanRole.owner) return -1;
        if (b.role == PlanRole.owner) return 1;
        return (a.handle ?? '').compareTo(b.handle ?? '');
      });
    return PlanSheetFrame(
      title: 'Members',
      subtitle:
          '${current.members.length} of ${current.limits.maxMembers} · '
          '${current.title}',
      closeButton: true,
      children: [
        const PlanShareLabel('People'),
        for (final (i, m) in members.indexed)
          _MemberRow(
            member: m,
            isMe: m.userId == me,
            last: i == members.length - 1,
            menu: iAmOwner && m.userId != me
                ? PlanPopupMenu<_MemberAction>(
                    tooltip: 'Change ${m.handle ?? 'member'}',
                    icon: Icons.more_vert,
                    iconColor: AppColors.mutedForeground,
                    onSelected: (a) =>
                        unawaited(_act(context, ref, current, m, a)),
                    entries: [
                      if (m.joined && m.role != PlanRole.owner)
                        if (!current.limits.roles)
                          const PlanMenuEntry(
                            _MemberAction.changeRole,
                            'Change role',
                            pro: true,
                          )
                        else if (m.role == PlanRole.viewer)
                          const PlanMenuEntry(
                            _MemberAction.makeEditor,
                            'Let them edit',
                          )
                        else
                          const PlanMenuEntry(
                            _MemberAction.makeViewer,
                            'Make view only',
                          ),
                      if (m.joined && m.role == PlanRole.editor)
                        const PlanMenuEntry(
                          _MemberAction.handOver,
                          'Make owner',
                        ),
                      PlanMenuEntry(
                        _MemberAction.remove,
                        m.joined ? 'Remove' : 'Cancel invitation',
                        destructive: true,
                      ),
                    ],
                  )
                : null,
          ),
        if (current.members.length < 2)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Just you so far. Use Invite to add a travel buddy.',
              style: AppTypeScale.small,
            ),
          ),
      ],
    );
  }
}

/// One person: avatar, username, "Can edit · joined", and the "⋮" for the
/// owner. Long usernames cut off with "…".
class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.last,
    this.menu,
  });

  final PlanMember member;
  final bool isMe;
  final bool last;
  final Widget? menu;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 60),
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: AppColors.exploreBorder)),
    ),
    child: Row(
      children: [
        PlanPersonAvatar(
          initial: member.initial,
          url: member.avatarUrl,
          size: 40,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.handle ?? '—',
                style: AppTypeScale.itemTitle.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                PlanPeopleSheet.detail(member, isMe: isMe),
                style: AppTypeScale.small,
              ),
            ],
          ),
        ),
        ?menu,
      ],
    ),
  );
}
