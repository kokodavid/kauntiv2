import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/services/app_share.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../design/app_colors.dart';
import '../application/plan_detail.dart';
import '../application/plan_sharing.dart';
import '../domain/plan_invite.dart';
import '../domain/plan_member.dart';
import '../domain/trip_plan.dart';
import 'plan_edit_sheets.dart';
import 'plan_invite_user_section.dart';
import 'plan_pro_sheet.dart';
import 'plan_sheet_frame.dart';

/// "Invite people" (design 8): a link to send, and people found by
/// username. Free has one travel buddy who can edit; Pro adds view-only.
Future<void> showPlanShareSheet(BuildContext context, TripPlan plan) =>
    showPlanSheet<void>(context, (_) => PlanShareSheet(plan: plan));

class PlanShareSheet extends ConsumerStatefulWidget {
  const PlanShareSheet({super.key, required this.plan});

  final TripPlan plan;

  @override
  ConsumerState<PlanShareSheet> createState() => _PlanShareSheetState();
}

class _PlanShareSheetState extends ConsumerState<PlanShareSheet> {
  PlanRole _role = PlanRole.editor;
  PlanInviteLink? _link;
  bool _busy = false;

  TripPlan get _plan =>
      ref.watch(planDetailProvider(widget.plan.id)).value?.plan ?? widget.plan;

  Future<void> _makeLink() async {
    setState(() => _busy = true);
    final (failure, link) = await ref
        .read(planSharingProvider)
        .createLink(widget.plan.id, _role);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _link = link ?? _link;
    });
    if (failure != null) reportPlanFailure(context, failure);
  }

  Future<void> _copy(PlanInviteLink link) async {
    await Clipboard.setData(ClipboardData(text: link.url));
    if (!mounted) return;
    showAppToast(context, variant: AppToastVariant.success, title: 'Link copied');
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final link = _link;
    final live = ref.watch(planInvitesProvider(plan.id)).value ?? const [];
    return PlanSheetFrame(
      title: 'Invite people',
      children: [
        if (plan.limits.roles)
          SegmentedButton<PlanRole>(
            segments: const [
              ButtonSegment(value: PlanRole.editor, label: Text('Can edit')),
              ButtonSegment(value: PlanRole.viewer, label: Text('View only')),
            ],
            selected: {_role},
            onSelectionChanged: (s) => setState(() => _role = s.first),
          )
        else
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your travel buddy can add and move places.',
                  style: AppTypeScale.small,
                ),
              ),
              TextButton(
                onPressed: () => unawaited(
                  showPlanProSheet(context, trigger: PlanProTrigger.invitee),
                ),
                child: const Text('More with Pro'),
              ),
            ],
          ),
        const SizedBox(height: 12),
        if (link == null)
          FilledButton.icon(
            onPressed: _busy ? null : () => unawaited(_makeLink()),
            icon: const Icon(Icons.link),
            label: Text(_busy ? 'Making link…' : 'Create invite link'),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lockedFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(link.url, style: AppTypeScale.body),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => unawaited(_copy(link)),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => unawaited(
                    AppShare.text(
                      'Join my trip plan "${plan.title}" on Kaunti47: '
                      '${link.url}',
                    ),
                  ),
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
          if (!plan.limits.roles)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Works for 7 days, until your buddy joins. A new link '
                'turns this one off.',
                style: AppTypeScale.small,
              ),
            ),
        ],
        if (live.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Active links', style: AppTypeScale.sectionLabel),
          for (final invite in live)
            _LiveLink(
              invite: invite,
              onTurnOff: () async {
                final failure = await ref
                    .read(planSharingProvider)
                    .revokeLink(plan.id, invite.id);
                if (failure != null && context.mounted) {
                  reportPlanFailure(context, failure);
                }
              },
            ),
        ],
        const SizedBox(height: 20),
        PlanInviteUserSection(plan: plan, role: _role),
      ],
    );
  }
}

class _LiveLink extends StatelessWidget {
  const _LiveLink({required this.invite, required this.onTurnOff});

  final PlanInviteInfo invite;
  final VoidCallback onTurnOff;

  @override
  Widget build(BuildContext context) {
    final role = invite.role == PlanRole.viewer ? 'View only' : 'Can edit';
    final until = MaterialLocalizations.of(context).formatShortDate(
      invite.expiresAt.toLocal(),
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            '$role · until $until · ${invite.uses} joined',
            style: AppTypeScale.small,
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
          onPressed: onTurnOff,
          child: const Text('Turn off'),
        ),
      ],
    );
  }
}
