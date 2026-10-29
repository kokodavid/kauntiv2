import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_limits.dart';

/// What sent the user to the Pro sheet (design 7b). Each has one line of
/// copy; the sheet never deletes or hides anything the user made.
enum PlanProTrigger {
  upcomingPlans,
  days,
  stops,
  places,
  invitee,
  bestOrder,
  offlineCopy;

  String get title => switch (this) {
    upcomingPlans => 'Plan more trips at once',
    days => 'Longer trips with Pro',
    stops => 'More stops with Pro',
    places => 'More places to visit with Pro',
    invitee => 'Plan as a group with Pro',
    bestOrder => 'Let Pro order the day',
    offlineCopy => 'Keep this plan offline',
  };

  String body(PlanLimits free, PlanLimits pro) => switch (this) {
    upcomingPlans =>
      'Free keeps ${free.maxUpcomingPlans} upcoming plans. Pro has no limit.',
    days =>
      'Free plans have ${free.maxDays} days. Pro plans go up to '
          '${pro.maxDays}.',
    stops =>
      'Free days hold ${free.maxStopsPerDay} stops. Pro days hold '
          '${pro.maxStopsPerDay}.',
    places =>
      'Free plans hold ${free.maxPlaces} places to visit. Pro holds '
          '${pro.maxPlaces}.',
    invitee =>
      'Free plans have 1 travel buddy. Pro plans hold up to '
          '${pro.maxMembers} people, with view-only roles.',
    bestOrder =>
      "Pro puts a day's stops in the shortest driving order. You can "
          'still reorder by hand.',
    offlineCopy =>
      "Pro saves the plan's map and places on this phone for weak signal.",
  };
}

/// "This is part of Pro" (design 7a). [onSeePro] opens the Pro overview;
/// [onArchive] is offered at the plan limit ("Archive a plan").
Future<void> showPlanProSheet(
  BuildContext context, {
  required PlanProTrigger trigger,
  VoidCallback? onSeePro,
  VoidCallback? onArchive,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  backgroundColor: AppColors.sheetBackground,
  barrierColor: AppColors.sheetBarrier,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (sheetContext) => _PlanProSheet(
    trigger: trigger,
    onSeePro: onSeePro == null
        ? null
        : () {
            Navigator.of(sheetContext).pop();
            onSeePro();
          },
    onArchive: onArchive == null
        ? null
        : () {
            Navigator.of(sheetContext).pop();
            onArchive();
          },
  ),
);

class _PlanProSheet extends StatelessWidget {
  const _PlanProSheet({required this.trigger, this.onSeePro, this.onArchive});

  final PlanProTrigger trigger;
  final VoidCallback? onSeePro;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    const free = PlanLimits.free;
    const pro = PlanLimits.proTier;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.sheetGrabber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft, child: PlanProTag()),
            const SizedBox(height: 10),
            Text(trigger.title, style: AppTypeScale.sectionTitle),
            const SizedBox(height: 4),
            Text(trigger.body(free, pro), style: AppTypeScale.body),
            const SizedBox(height: 16),
            _CompareRow(
              label: 'Free',
              value:
                  '${free.maxUpcomingPlans} upcoming · ${free.maxDays} days · '
                  '1 buddy',
            ),
            const SizedBox(height: 8),
            _CompareRow(
              label: 'Pro',
              value: 'Unlimited · ${pro.maxDays} days · groups of '
                  '${pro.maxMembers}',
              highlight: true,
            ),
            const SizedBox(height: 10),
            const Text(
              'Your plans stay exactly as they are.',
              style: AppTypeScale.meta,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.accentForeground,
                  shape: const StadiumBorder(),
                ),
                // Until the Pro overview exists, the sheet only explains.
                onPressed: onSeePro ?? () => Navigator.of(context).pop(),
                child: Text(onSeePro == null ? 'Got it' : 'See Pro'),
              ),
            ),
            if (onArchive != null)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: onArchive,
                child: const Text('Archive a plan'),
              ),
            if (onSeePro != null)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.foreground,
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Not now'),
              ),
          ],
        ),
      ),
    );
  }
}

/// The small "PRO" tag next to a Pro-only action.
class PlanProTag extends StatelessWidget {
  const PlanProTag({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.accentTint,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.infoBorder),
    ),
    child: const Text(
      'PRO',
      style: TextStyle(
        fontFamily: AppTypeScale.family,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.accentDark,
      ),
    ),
  );
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: highlight ? AppColors.accentTint : AppColors.noteBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: highlight ? AppColors.infoBorder : AppColors.softDivider,
      ),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: AppTypeScale.itemTitle),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypeScale.small.copyWith(
              color: highlight ? AppColors.accentDark : AppColors.bodyText,
            ),
          ),
        ),
      ],
    ),
  );
}
