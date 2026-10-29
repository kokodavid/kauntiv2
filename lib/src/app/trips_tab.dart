import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_segmented_tabs.dart';
import '../design/app_colors.dart';
import '../features/journeys/application/journey_recorder.dart';
import '../features/journeys/presentation/journeys_screen.dart';
import '../features/onboarding/application/startup_flow.dart';
import '../features/trip_plans/application/planned_trips_list.dart';
import '../features/trip_plans/application/trip_plans_providers.dart';
import '../features/trip_plans/application/trips_segment.dart';
import '../features/trip_plans/domain/planned_trips.dart';
import '../features/trip_plans/presentation/planned_view.dart';
import '../features/trip_plans/presentation/start_plan_trip.dart';
import 'app_routes.dart';
import 'detail_routes.dart';

/// The Trips tab. With the planner switched on it has two halves, Planned
/// (trip plans) and Recorded (today's Trips page); otherwise it is the
/// Recorded page alone, exactly as before. The halves come from two
/// features, so they are put together here.
class TripsTab extends ConsumerWidget {
  const TripsTab({super.key});

  /// Today's Trips page, with the switch drawn under its title.
  static Widget recorded(Widget? header) => JourneysScreen(
    header: header,
    onOpenJourney: (context, id) => context.push(AppRoutes.journey(id)),
    onOpenSettings: DetailRoutes.openAppSettings,
    onOpenRecording: (context) => context.push(AppRoutes.journeyRecording),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(tripPlansEnabledProvider).value ?? false;
    if (!enabled) return recorded(null);

    final recording = ref.watch(journeyRecorderProvider) != null;
    final list = ref.watch(plannedTripsListProvider).value;
    final choice = ref.watch(tripsSegmentChoiceProvider);
    final known = recording || list != null;
    if (choice == null && known) {
      // Latch the opening half once, after this frame (decision 1).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref
            .read(tripsSegmentChoiceProvider.notifier)
            .resolveDefault(
              recording: recording,
              hasUpcomingPlan: list?.plans.hasUpcoming ?? false,
            );
      });
    }
    final segment =
        choice ??
        (known
            ? defaultTripsSegment(
                recording: recording,
                hasUpcomingPlan: list?.plans.hasUpcoming ?? false,
              )
            : TripsSegment.recorded);

    final header = AppSegmentedTabs<TripsSegment>(
      options: TripsSegment.values,
      labelOf: (s) => s == TripsSegment.planned ? 'Planned' : 'Recorded',
      selected: segment,
      onChanged: ref.read(tripsSegmentChoiceProvider.notifier).select,
    );
    if (segment == TripsSegment.recorded) return recorded(header);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: PlannedView(
          header: header,
          onPlanTrip: () => unawaited(startPlanTrip(context, ref)),
          onFindPlaces: () => context.go(AppRoutes.explore),
          homeCountyCode: ref.watch(
            startupFlowProvider.select((s) => s.homeCounty?.code),
          ),
        ),
      ),
    );
  }
}
