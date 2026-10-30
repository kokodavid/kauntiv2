import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_labels.dart';
import '../domain/plan_member.dart';
import '../domain/trip_plan.dart';
import 'plan_header_people.dart';

/// The top of the plan screen (design 3a, 3b): back, title and dates, then
/// the Invite pill (a plan nobody has joined) or who is on it, and the "…".
/// The "view only" and offline notes sit under the title.
class PlanHeader extends StatelessWidget {
  const PlanHeader({
    super.key,
    required this.plan,
    required this.onBack,
    this.offline = false,
    this.savedAt,
    this.menu,
    this.onInvite,
    this.onPeople,
  });

  final TripPlan plan;
  final VoidCallback onBack;
  final bool offline;
  final DateTime? savedAt;

  /// The plan's "…" for people who can edit.
  final Widget? menu;

  /// Opens the invite sheet; null when this person can't invite.
  final VoidCallback? onInvite;

  /// Opens People.
  final VoidCallback? onPeople;

  static String _time(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final dates = plan.startDate == null
        ? 'No date yet'
        : PlanLabels.range(plan.startDate, plan.endDate);
    final joined = plan.members.where((m) => m.joined).toList();
    final notes = [
      if (offline)
        savedAt == null
            ? 'Offline · saved copy'
            : 'Offline · saved copy from ${_time(savedAt!.toLocal())}',
      if (plan.role == PlanRole.viewer) 'View only',
    ];
    final Widget? people = joined.length > 1
        ? PlanHeaderPeople(
            members: joined,
            onPeople: onPeople ?? () {},
            onInvite: onInvite,
          )
        : onInvite != null
        ? PlanInvitePill(onPressed: onInvite!)
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBackButton(onPressed: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: AppTypeScale.sectionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(dates, style: AppTypeScale.small),
                  if (notes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        notes.join(' · '),
                        style: AppTypeScale.meta.copyWith(
                          color: AppColors.warningText,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (people != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: people,
            ),
          ?menu,
        ],
      ),
    );
  }
}
