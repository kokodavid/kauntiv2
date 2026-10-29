import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/onboarding/application/startup_flow.dart';
import '../features/trip_plans/presentation/plan_screen.dart';
import 'app_routes.dart';

/// The trip plan screen, pushed over the tab bar from the Planned list.
final planRoutes = <RouteBase>[
  GoRoute(
    path: '/plan/:id',
    builder: (context, state) => _PlanPage(planId: state.pathParameters['id']!),
  ),
];

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
  );
}
