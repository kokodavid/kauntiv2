import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/onboarding/application/startup_flow.dart';
import '../features/trip_planner/presentation/saved_plans_home_section.dart';
import '../features/trip_plans/application/trip_plans_providers.dart';
import '../features/trip_plans/presentation/next_plan_card.dart';
import 'app_routes.dart';
import 'detail_routes.dart';

/// Home's plans section: the next trip plan when the planner is on, the
/// old saved plans while it is off.
class HomePlansSection extends ConsumerWidget {
  const HomePlansSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(tripPlansEnabledProvider).value ?? false) {
      return NextPlanCard(
        homeCountyCode: ref.watch(
          startupFlowProvider.select((s) => s.homeCounty?.code),
        ),
        onOpenPlan: (context, id) => context.push(AppRoutes.plan(id)),
      );
    }
    return SavedPlansHomeSection(
      onOpenPlace: DetailRoutes.openPlace!,
      onSeeAll: () => context.push(AppRoutes.savedPlans),
    );
  }
}
