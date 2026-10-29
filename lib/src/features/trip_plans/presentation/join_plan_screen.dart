import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../design/app_colors.dart';
import '../application/plan_collaboration_providers.dart';
import '../domain/plan_invite.dart';
import '../domain/plan_member.dart';

typedef OpenJoinedPlan = void Function(String planId);

/// What opens from an invite link: who invited you to which plan, and a
/// button to join, or why the link no longer works.
class JoinPlanScreen extends ConsumerStatefulWidget {
  const JoinPlanScreen({
    super.key,
    required this.token,
    required this.signedIn,
    required this.onOpenPlan,
    required this.onClose,
    this.onSignIn,
  });

  final String token;
  final bool signedIn;
  final OpenJoinedPlan onOpenPlan;
  final VoidCallback onClose;
  final VoidCallback? onSignIn;

  @override
  ConsumerState<JoinPlanScreen> createState() => _JoinPlanScreenState();
}

class _JoinPlanScreenState extends ConsumerState<JoinPlanScreen> {
  bool _joining = false;

  Future<void> _join() async {
    setState(() => _joining = true);
    final (failure, planId) = await ref.read(planJoinerProvider).join(
      widget.token,
    );
    if (!mounted) return;
    setState(() => _joining = false);
    if (failure != null) {
      showAppToast(
        context,
        variant: AppToastVariant.error,
        title: "Couldn't join",
        message: failure.message,
      );
      return;
    }
    if (planId != null) widget.onOpenPlan(planId);
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.signedIn
        ? ref.watch(invitePreviewProvider(widget.token))
        : null;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: preview == null
              ? _Message(
                  title: 'Sign in to join this plan',
                  body: 'Your invite will be waiting.',
                  action: widget.onSignIn == null
                      ? null
                      : _Action('Sign in', widget.onSignIn!),
                )
              : preview.when(
                  loading: () => const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) => _Message(
                    title: "Couldn't check this link",
                    body: 'Check your connection and try again.',
                    action: _Action(
                      'Try again',
                      () => ref.invalidate(invitePreviewProvider(widget.token)),
                    ),
                  ),
                  data: _content,
                ),
        ),
      ),
    );
  }

  Widget _content(InvitePreview preview) {
    final who = preview.inviterHandle ?? 'Someone';
    final title = preview.title ?? 'a trip';
    switch (preview.state) {
      case InviteState.ok:
        final viewOnly = preview.role == PlanRole.viewer;
        return _Message(
          title: '$who invited you to $title',
          body: viewOnly
              ? "You'll be able to see this plan, not change it."
              : "You'll be able to add and move places in this plan.",
          action: _Action(
            _joining ? 'Joining…' : 'Join plan',
            _joining ? null : () => unawaited(_join()),
          ),
        );
      case InviteState.alreadyMember:
        return _Message(
          title: "You're already on $title",
          body: 'Open it from here.',
          action: _Action('Open plan', () {
            final id = preview.planId;
            if (id != null) widget.onOpenPlan(id);
          }),
        );
      case InviteState.expired:
        return _Message(
          title: 'This link has expired',
          body: preview.inviterHandle == null
              ? 'Ask for a new link.'
              : 'Ask ${preview.inviterHandle} for a new link.',
        );
      case InviteState.revoked:
        return const _Message(
          title: 'This link was turned off',
          body: 'Ask for a new link.',
        );
      case InviteState.full:
        return const _Message(
          title: 'This plan is full',
          body: 'There is no room for another person right now.',
        );
      case InviteState.invalid:
        return const _Message(
          title: "We can't find this invite",
          body: 'Check the link, or ask for a new one.',
        );
    }
  }
}

class _Action {
  const _Action(this.label, this.onPressed);

  final String label;
  final VoidCallback? onPressed;
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body, this.action});

  final String title;
  final String body;
  final _Action? action;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.group_outlined, size: 36, color: AppColors.green),
      const SizedBox(height: 12),
      Text(title, textAlign: TextAlign.center, style: AppTypeScale.cardTitle),
      const SizedBox(height: 6),
      Text(body, textAlign: TextAlign.center, style: AppTypeScale.small),
      if (action != null) ...[
        const SizedBox(height: 20),
        FilledButton(
          onPressed: action!.onPressed,
          child: Text(action!.label),
        ),
      ],
    ],
  );
}
