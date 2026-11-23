import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_invite.dart';
import '../domain/plan_member.dart';

/// Small uppercase label over a section ("INVITE BY LINK").
class PlanShareLabel extends StatelessWidget {
  const PlanShareLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text.toUpperCase(), style: AppTypeScale.sectionLabel),
  );
}

/// "NEW PEOPLE CAN": Edit or View only (Pro), a grey track with a white
/// pill under the chosen one.
class PlanRoleSwitch extends StatelessWidget {
  const PlanRoleSwitch({
    super.key,
    required this.role,
    required this.onChanged,
  });

  final PlanRole role;
  final ValueChanged<PlanRole> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppColors.secondaryFill,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      children: [
        _Segment(
          'Edit',
          role == PlanRole.editor,
          () => onChanged(PlanRole.editor),
        ),
        _Segment(
          'View only',
          role == PlanRole.viewer,
          () => onChanged(PlanRole.viewer),
        ),
      ],
    ),
  );
}

class _Segment extends StatelessWidget {
  const _Segment(this.label, this.selected, this.onTap);

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTypeScale.action.copyWith(
              color: selected
                  ? AppColors.foreground
                  : AppColors.mutedForeground,
            ),
          ),
        ),
      ),
    ),
  );
}

/// The link in a pill, with Copy and Share beside it.
class PlanLinkRow extends StatelessWidget {
  const PlanLinkRow({
    super.key,
    required this.url,
    required this.onCopy,
    required this.onShare,
  });

  final String url;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.exploreSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.exploreBorder),
          ),
          child: Text(
            url,
            style: AppTypeScale.itemTitle.copyWith(fontWeight: FontWeight.w400),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      const SizedBox(width: 8),
      TextButton(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.foreground,
          backgroundColor: AppColors.secondaryFill,
          textStyle: AppTypeScale.action.copyWith(fontWeight: FontWeight.w600),
          minimumSize: const Size(64, 44),
          shape: const StadiumBorder(),
        ),
        onPressed: onCopy,
        child: const Text('Copy'),
      ),
      const SizedBox(width: 8),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.accentForeground,
          textStyle: AppTypeScale.action.copyWith(fontWeight: FontWeight.w600),
          minimumSize: const Size(72, 44),
          shape: const StadiumBorder(),
        ),
        onPressed: onShare,
        child: const Text('Share'),
      ),
    ],
  );
}

/// "Link expires in 7 days" and "Turn off link".
class PlanLinkFooter extends StatelessWidget {
  const PlanLinkFooter({
    super.key,
    required this.expiresAt,
    required this.onTurnOff,
  });

  final DateTime expiresAt;
  final VoidCallback onTurnOff;

  static String expiry(DateTime at, DateTime now) {
    final days = at.difference(now).inHours / 24;
    if (days < 1) return 'Link expires today';
    final whole = days.round();
    return whole == 1 ? 'Link expires in 1 day' : 'Link expires in $whole days';
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          expiry(expiresAt, DateTime.now()),
          style: AppTypeScale.small,
        ),
      ),
      TextButton(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.danger,
          textStyle: AppTypeScale.action,
          minimumSize: const Size(44, 44),
        ),
        onPressed: onTurnOff,
        child: const Text('Turn off link'),
      ),
    ],
  );
}

/// An older link that is still on ("Can edit · until 6 Nov · 0 joined").
class PlanLiveLink extends StatelessWidget {
  const PlanLiveLink({
    super.key,
    required this.invite,
    required this.onTurnOff,
  });

  final PlanInviteInfo invite;
  final VoidCallback onTurnOff;

  @override
  Widget build(BuildContext context) {
    final role = invite.role == PlanRole.viewer ? 'View only' : 'Can edit';
    final until = MaterialLocalizations.of(
      context,
    ).formatShortDate(invite.expiresAt.toLocal());
    return Row(
      children: [
        Expanded(
          child: Text(
            '$role · until $until · ${invite.uses} joined',
            style: AppTypeScale.small,
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.danger,
            textStyle: AppTypeScale.action,
            minimumSize: const Size(44, 44),
          ),
          onPressed: onTurnOff,
          child: const Text('Turn off'),
        ),
      ],
    );
  }
}
