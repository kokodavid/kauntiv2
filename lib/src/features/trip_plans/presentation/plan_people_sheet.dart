import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../auth/application/auth_providers.dart';
import '../application/plan_detail.dart';
import '../application/plan_sharing.dart';
import '../domain/plan_member.dart';
import '../domain/trip_plan.dart';
import 'plan_edit_sheets.dart';
import 'plan_sheet_frame.dart';

/// Who is on the plan, and for the owner how to change that.
Future<void> showPlanPeopleSheet(BuildContext context, TripPlan plan) =>
    showPlanSheet<void>(context, (_) => PlanPeopleSheet(plan: plan));

enum _MemberAction { makeEditor, makeViewer, handOver, remove }

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

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    TripPlan current,
    PlanMember member,
    _MemberAction action,
  ) async {
    final sharing = ref.read(planSharingProvider);
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
      title: 'People',
      children: [
        for (final m in members)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: PlanPersonAvatar(initial: m.initial, url: m.avatarUrl),
            title: Text(
              m.userId == me ? '${m.handle ?? 'You'} (you)' : m.handle ?? '—',
            ),
            subtitle: Text(roleLabel(m), style: AppTypeScale.small),
            trailing: iAmOwner && m.userId != me
                ? PopupMenuButton<_MemberAction>(
                    tooltip: 'Change ${m.handle ?? 'member'}',
                    onSelected: (a) =>
                        unawaited(_act(context, ref, current, m, a)),
                    itemBuilder: (_) => [
                      if (current.limits.roles && m.joined)
                        if (m.role == PlanRole.viewer)
                          const PopupMenuItem(
                            value: _MemberAction.makeEditor,
                            child: Text('Let them edit'),
                          )
                        else
                          const PopupMenuItem(
                            value: _MemberAction.makeViewer,
                            child: Text('Make view only'),
                          ),
                      if (m.joined && m.role == PlanRole.editor)
                        const PopupMenuItem(
                          value: _MemberAction.handOver,
                          child: Text('Make owner'),
                        ),
                      PopupMenuItem(
                        value: _MemberAction.remove,
                        child: Text(m.joined ? 'Remove' : 'Cancel invitation'),
                      ),
                    ],
                  )
                : null,
          ),
        if (current.members.length < 2)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Just you so far. Use Invite people to add a travel buddy.',
              style: AppTypeScale.small,
            ),
          ),
      ],
    );
  }
}
