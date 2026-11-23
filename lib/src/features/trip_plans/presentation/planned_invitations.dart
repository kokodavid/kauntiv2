import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../design/app_colors.dart';
import '../application/plan_sharing.dart';
import '../domain/plan_invite.dart';
import '../domain/plan_member.dart';
import 'plan_edit_sheets.dart';
import 'planned_section.dart';

/// Invitations by username waiting on Planned: Accept or Decline. Nothing
/// shows when there are none.
class PlannedInvitations extends ConsumerWidget {
  const PlannedInvitations({super.key, this.onOpenPlan});

  final void Function(BuildContext context, String planId)? onOpenPlan;

  Future<void> _answer(
    BuildContext context,
    WidgetRef ref,
    PlanInvitation invitation, {
    required bool accept,
  }) async {
    final failure = await ref
        .read(planSharingProvider)
        .respond(invitation.planId, accept: accept);
    if (!context.mounted) return;
    if (failure != null) {
      reportPlanFailure(context, failure);
      return;
    }
    if (accept) {
      showAppToast(
        context,
        variant: AppToastVariant.success,
        title: 'Joined ${invitation.title}',
      );
      onOpenPlan?.call(context, invitation.planId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(myPlanInvitationsProvider).value ?? const [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PlannedSectionHeader(title: 'Invitations'),
        for (final invitation in list)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invitation.title, style: AppTypeScale.cardTitle),
                const SizedBox(height: 2),
                Text(
                  '${invitation.inviterHandle ?? 'Someone'} invited you · '
                  '${invitation.role == PlanRole.viewer ? 'view only' : 'can edit'}',
                  style: AppTypeScale.small,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () => unawaited(
                        _answer(context, ref, invitation, accept: true),
                      ),
                      child: const Text('Accept'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => unawaited(
                        _answer(context, ref, invitation, accept: false),
                      ),
                      child: const Text('Decline'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
