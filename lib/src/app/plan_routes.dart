import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/domain/app_feature_flags.dart';
import '../features/onboarding/application/startup_flow.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/trip_plans/presentation/join_plan_screen.dart';
import '../features/trip_plans/presentation/plan_screen.dart';
import 'app_routes.dart';
import 'plan_start_day.dart';

/// The trip plan screen, pushed over the tab bar from the Planned list.
final planRoutes = <RouteBase>[
  GoRoute(
    path: '/plan/:id',
    builder: (context, state) => _PlanPage(planId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/p/:code',
    builder: (context, state) => _JoinPage(code: state.pathParameters['code']!),
  ),
];

/// An invite link: join the plan, then open it in place of this page.
class _JoinPage extends ConsumerWidget {
  const _JoinPage({required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) => JoinPlanScreen(
    token: code,
    signedIn: ref.watch(currentUserIdProvider)() != null,
    onClose: () => context.canPop() ? context.pop() : context.go(AppRoutes.map),
    onOpenPlan: (id) => context.pushReplacement(AppRoutes.plan(id)),
  );
}

class _PlanPage extends ConsumerWidget {
  const _PlanPage({required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PlanScreen(
    planId: planId,
    homeCountyCode: ref.watch(
      startupFlowProvider.select((s) => s.homeCounty?.code),
    ),
    onBack: () => Navigator.of(context).maybePop(),
    onOpenPlace: (context, id) => context.push(AppRoutes.place(id)),
    onStartDay: AppFeatureFlags.journeys ? startPlanDay : null,
    onWatchReplay: (context, id) => context.push(AppRoutes.journey(id)),
  );
}
