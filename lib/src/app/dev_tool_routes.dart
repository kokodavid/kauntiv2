import 'package:go_router/go_router.dart';

import '../features/notifications/presentation/push_status_screen.dart';
import 'app_routes.dart';

/// Screens reached from Settings, Developer. The router only adds these in
/// dev builds. They are real routes (not a pushed MaterialPageRoute) because
/// the Settings callbacks run above the router's Navigator.
final devToolRoutes = <GoRoute>[
  GoRoute(
    path: AppRoutes.pushStatus,
    builder: (context, state) => const PushStatusScreen(),
  ),
];
