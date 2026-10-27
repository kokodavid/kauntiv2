import 'package:go_router/go_router.dart';

import '../features/app_version/presentation/forced_update_screen.dart';
import 'app_routes.dart';

/// Only the blocking update lives on a route. The soft update is a sheet
/// over the app (see `SoftUpdateHost`) so it never replaces Home.
List<RouteBase> appUpdateRoutes() => [
  GoRoute(
    path: AppRoutes.updateRequired,
    pageBuilder: (context, state) =>
        NoTransitionPage(child: ForcedUpdateScreen(key: state.pageKey)),
  ),
];
