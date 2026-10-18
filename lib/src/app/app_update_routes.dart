import 'package:go_router/go_router.dart';

import '../features/app_version/presentation/app_update_screen.dart';
import 'app_routes.dart';

List<RouteBase> appUpdateRoutes() => [
  GoRoute(
    path: AppRoutes.updateRequired,
    pageBuilder: (context, state) =>
        NoTransitionPage(child: AppUpdateScreen(key: state.pageKey)),
  ),
  GoRoute(
    path: AppRoutes.updateAvailable,
    pageBuilder: (context, state) => NoTransitionPage(
      child: AppUpdateScreen(
        key: state.pageKey,
        onLater: () => context.go(AppRoutes.map),
      ),
    ),
  ),
];
