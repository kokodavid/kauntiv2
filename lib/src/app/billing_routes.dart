import 'package:go_router/go_router.dart';

import '../features/billing/presentation/upgrade_screen.dart';
import 'app_routes.dart';

/// The Pro purchase screen. It is only reachable from the Membership sheet,
/// which only shows its button while the dashboard's billing switch is on.
final billingRoutes = <GoRoute>[
  GoRoute(
    path: AppRoutes.upgrade,
    builder: (context, state) => const UpgradeScreen(),
  ),
];
