import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/plan_member.dart';
import 'plan_avatar_stack.dart';

const _tapSize = 44.0;

/// "Invite" pill (design 3a): a soft accent pill for a plan nobody has
/// joined yet.
class PlanInvitePill extends StatelessWidget {
  const PlanInvitePill({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Invite people',
    child: Material(
      color: AppColors.accentTint,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add_alt, size: 20, color: AppColors.accent),
              SizedBox(width: 6),
              Text(
                'Invite',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Who is on a shared plan (design 3b): their avatars, and a "+" that
/// invites more when the person may. Tapping the avatars opens People.
class PlanHeaderPeople extends StatelessWidget {
  const PlanHeaderPeople({
    super.key,
    required this.members,
    required this.onPeople,
    this.onInvite,
  });

  final List<PlanMember> members;
  final VoidCallback onPeople;

  /// Null when this person can't invite.
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        button: true,
        label: 'People on this plan',
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPeople,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _tapSize),
            child: Center(
              child: PlanAvatarStack(members: members, size: 36, max: 3),
            ),
          ),
        ),
      ),
      if (onInvite != null)
        Semantics(
          button: true,
          label: 'Invite people',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onInvite,
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 2),
              decoration: const BoxDecoration(
                color: AppColors.accentTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 20, color: AppColors.accent),
            ),
          ),
        ),
    ],
  );
}
