import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/offline_screen.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/planned_trips_list.dart';
import '../application/trip_plans_providers.dart';
import '../domain/plan_limits.dart';
import '../domain/planned_trips.dart';
import '../domain/trip_plan_summary.dart';
import 'plan_card.dart';
import 'plan_trip_button.dart';
import 'planned_archived_section.dart';
import 'planned_empty_state.dart';
import 'planned_invitations.dart';
import 'planned_section.dart';
import 'planned_skeleton.dart';

/// Opens a plan's screen.
typedef OpenTripPlan = void Function(BuildContext context, String planId);

/// The Planned half of the Trips tab (design 1a to 1c, 1e): Plan a trip,
/// then Upcoming, Shared with you and Past. [header] is the Planned /
/// Recorded switch, drawn at the right of the title like on Recorded.
class PlannedView extends ConsumerStatefulWidget {
  const PlannedView({
    super.key,
    required this.header,
    required this.onPlanTrip,
    this.onOpenPlan,
    this.onFindPlaces,
    this.homeCountyCode,
  });

  final Widget header;

  /// The user's home county, which reads as "home" on routes.
  final int? homeCountyCode;

  /// Starts a new plan (the create sheet, or the Pro sheet at the limit).
  final VoidCallback onPlanTrip;
  final OpenTripPlan? onOpenPlan;
  final VoidCallback? onFindPlaces;

  @override
  ConsumerState<PlannedView> createState() => _PlannedViewState();
}

class _PlannedViewState extends ConsumerState<PlannedView> {
  bool _showPast = false;
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(plannedTripsListProvider);
    final limits = ref.watch(myPlanLimitsProvider).value ?? PlanLimits.free;
    final view = list.value;
    final Widget body;
    if (view != null) {
      body = !view.plans.hasActive
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Someone may have invited you before you have any plan.
                if (!view.offline)
                  PlannedInvitations(onOpenPlan: widget.onOpenPlan),
                PlannedEmptyState(
                  limits: limits,
                  onPlanTrip: widget.onPlanTrip,
                  onFindPlaces: widget.onFindPlaces,
                ),
                // Plans put away still come back from here.
                if (!view.offline)
                  PlannedArchivedSection(
                    plans: view.plans.archived,
                    open: _showArchived,
                    onToggle: () =>
                        setState(() => _showArchived = !_showArchived),
                    onOpenPlan: widget.onOpenPlan,
                    homeCode: widget.homeCountyCode,
                  ),
              ],
            )
          : _Sections(
              plans: view.plans,
              limits: limits,
              offline: view.offline,
              showPast: _showPast,
              onTogglePast: () => setState(() => _showPast = !_showPast),
              showArchived: _showArchived,
              onToggleArchived: () =>
                  setState(() => _showArchived = !_showArchived),
              onPlanTrip: widget.onPlanTrip,
              onOpenPlan: widget.onOpenPlan,
              homeCode: widget.homeCountyCode,
            );
    } else if (list.hasError) {
      return _Frame(
        header: widget.header,
        child: SizedBox(
          height: 480,
          child: OfflineScreen(
            message:
                'Your plans load from the internet. Check your data or '
                'Wi‑Fi, then try again.',
            onRetry: () => ref.invalidate(plannedTripsListProvider),
          ),
        ),
      );
    } else {
      body = const PlannedSkeleton();
    }
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async {
        await ref.read(plannedTripsListProvider.notifier).refresh();
        ref.invalidate(myPlanLimitsProvider);
      },
      child: _Frame(header: widget.header, child: body),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.header, required this.child});

  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    // Room for the floating tab bar.
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
    children: [
      Row(
        children: [
          const Expanded(
            child: Text('Trips', style: AppTextStyles.headingForeground),
          ),
          header,
        ],
      ),
      const SizedBox(height: 16),
      child,
    ],
  );
}

class _Sections extends ConsumerWidget {
  const _Sections({
    required this.plans,
    required this.limits,
    required this.offline,
    required this.showPast,
    required this.onTogglePast,
    required this.showArchived,
    required this.onToggleArchived,
    required this.onPlanTrip,
    this.onOpenPlan,
    this.homeCode,
  });

  final PlannedTrips plans;
  final PlanLimits limits;
  final bool offline;
  final bool showPast;
  final VoidCallback onTogglePast;
  final bool showArchived;
  final VoidCallback onToggleArchived;
  final VoidCallback onPlanTrip;
  final OpenTripPlan? onOpenPlan;
  final int? homeCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimed = ref.watch(planClaimedCountyCodesProvider).value ?? <int>{};
    Widget card(TripPlanSummary plan) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PlanCard(
        plan: plan,
        claimed: claimed,
        homeCode: homeCode,
        onTap: onOpenPlan == null ? null : () => onOpenPlan!(context, plan.id),
      ),
    );
    final counted = plans.countedUpcoming;
    // "2 of 3 upcoming plans" only once it matters (design 1b note).
    final countLine = !limits.pro && counted >= 2
        ? '$counted of ${limits.maxUpcomingPlans ?? 3} upcoming plans'
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (offline) const _OfflineNote(),
        if (!offline) PlanTripButton(onPressed: onPlanTrip),
        if (!offline) PlannedInvitations(onOpenPlan: onOpenPlan),
        if (plans.upcoming.isNotEmpty) ...[
          PlannedSectionHeader(title: 'Upcoming', subtitle: countLine),
          for (final plan in plans.upcoming) card(plan),
        ],
        if (plans.shared.isNotEmpty) ...[
          const PlannedSectionHeader(title: 'Shared with you'),
          for (final plan in plans.shared) card(plan),
        ],
        if (plans.past.isNotEmpty) ...[
          PlannedSectionHeader(
            title: 'Past',
            actionLabel: showPast ? 'Hide' : 'Show ${plans.past.length} ›',
            onAction: onTogglePast,
          ),
          if (showPast)
            for (final plan in plans.past) card(plan),
        ],
        if (!offline)
          PlannedArchivedSection(
            plans: plans.archived,
            open: showArchived,
            onToggle: onToggleArchived,
            onOpenPlan: onOpenPlan,
            homeCode: homeCode,
          ),
      ],
    );
  }
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.noteBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.exploreBorder),
    ),
    child: const Text(
      "You're offline. These are the plans saved on this phone; making "
      'changes comes back when you reconnect.',
      style: AppTypeScale.small,
    ),
  );
}
