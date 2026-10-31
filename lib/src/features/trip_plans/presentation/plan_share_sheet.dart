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
import '../application/trip_plans_providers.dart';
import '../domain/plan_invite.dart';
import '../domain/plan_member.dart';
import '../domain/trip_plan.dart';
import 'plan_edit_sheets.dart';
import 'plan_invite_user_section.dart';
import 'plan_share_parts.dart';
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

  Future<void> _turnOff(String inviteId, {bool current = false}) async {
    final failure = await ref
        .read(planSharingProvider)
        .revokeLink(widget.plan.id, inviteId);
    if (!mounted) return;
    if (failure != null) {
      reportPlanFailure(context, failure);
    } else if (current) {
      setState(() => _link = null);
    }
  }

  /// The link without "https://", as the design shows it.
  static String _shown(String url) => url.replaceFirst('https://', '');

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final link = _link;
    final links = ref.watch(tripPlanLinksEnabledProvider).value ?? false;
    final pro = plan.limits.roles;
    final joined = plan.members.where((m) => m.joined).length;
    final others = [
      for (final i
          in ref.watch(planInvitesProvider(plan.id)).value ??
              const <PlanInviteInfo>[])
        if (i.id != link?.id) i,
    ];
    return PlanSheetFrame(
      title: pro ? 'Invite people' : 'Invite a travel buddy',
      subtitle: pro
          ? '$joined of ${plan.limits.maxMembers} people'
          : 'Free plans have ${plan.limits.maxMembers - 1} travel buddy · '
                '${(joined - 1).clamp(0, 99)} of ${plan.limits.maxMembers - 1}',
      closeButton: true,
      children: [
        if (pro) ...[
          const PlanShareLabel('New people can'),
          PlanRoleSwitch(
            role: _role,
            onChanged: (r) => setState(() => _role = r),
          ),
        ],
        if (links) ...[
          const PlanShareLabel('Invite by link'),
          if (link == null)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.accentForeground,
                textStyle: AppTypeScale.action.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                minimumSize: const Size.fromHeight(44),
                shape: const StadiumBorder(),
              ),
              onPressed: _busy ? null : () => unawaited(_makeLink()),
              icon: const Icon(Icons.link, size: 18),
              label: Text(_busy ? 'Making link…' : 'Create invite link'),
            )
          else ...[
            PlanLinkRow(
              url: _shown(link.url),
              onCopy: () => unawaited(_copy(link)),
              onShare: () => unawaited(
                AppShare.text(
                  'Join my trip plan "${plan.title}" on Kaunti47: ${link.url}',
                ),
              ),
            ),
            PlanLinkFooter(
              expiresAt: link.expiresAt,
              onTurnOff: () => unawaited(_turnOff(link.id, current: true)),
            ),
          ],
          for (final invite in others)
            PlanLiveLink(
              invite: invite,
              onTurnOff: () => unawaited(_turnOff(invite.id)),
            ),
        ],
        PlanInviteUserSection(plan: plan, role: _role),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            pro
                ? "You can change anyone's role later in Members."
                : 'They can add and move places. Only usernames are shown.',
            style: AppTypeScale.small,
          ),
        ),
        if (!pro)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                textStyle: AppTypeScale.action,
                minimumSize: const Size(44, 44),
                padding: EdgeInsets.zero,
              ),
              onPressed: () => unawaited(
                showPlanProSheet(context, trigger: PlanProTrigger.invitee),
              ),
              child: const Text('More with Pro'),
            ),
          ),
      ],
    );
  }
}
