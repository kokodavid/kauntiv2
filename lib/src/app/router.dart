import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/services/app_config_provider.dart';
import '../features/discover/presentation/county_detail_screen.dart';
import '../features/discover/presentation/explore_screen.dart';
import '../features/discover/presentation/place_detail_screen.dart';
import '../features/map_home/application/map_home_board_loader.dart';
import '../features/map_home/data/supabase_map_home_repository.dart';
import '../features/map_home/presentation/map_home_screen.dart';
import '../features/onboarding/application/startup_flow.dart';
import '../services/app_supabase.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'detail_routes.dart';
import 'startup_pages.dart';

part 'router.g.dart';

/// The app's router (architecture §5). Start-up gating is one redirect on
/// [StartupFlow]'s step; the tabs are a [StatefulShellRoute]; County and
/// Place Detail push over the shell on the root navigator.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) => AppRoutes.redirect(
      ref.read(startupFlowProvider).step,
      state.matchedLocation,
    ),
    routes: [
      _gate(AppRoutes.splash, const StartupSplashPage()),
      _gate(AppRoutes.signIn, const StartupSignInPage()),
      _gate(AppRoutes.homeCounty, const StartupHomeCountyPage()),
      _gate(AppRoutes.permission, const StartupPermissionPage()),
      StatefulShellRoute.indexedStack(
        // Swapped in place like the gates, not slid in.
        pageBuilder: (context, state, shell) =>
            NoTransitionPage(child: AppShell(navigationShell: shell)),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.map,
                builder: (context, state) => const _MapTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.explore,
                builder: (context, state) => ExploreScreen(
                  onOpenCounty: DetailRoutes.openCounty,
                  onOpenPlace: DetailRoutes.openPlace,
                  onRoute: DetailRoutes.openDirections,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/county/:code',
        builder: (context, state) => CountyDetailScreen(
          countyCode: int.parse(state.pathParameters['code']!),
          actions: DetailRoutes.actions!,
        ),
      ),
      GoRoute(
        path: '/place/:id',
        builder: (context, state) => PlaceDetailScreen(
          placeId: state.pathParameters['id']!,
          actions: DetailRoutes.actions!,
        ),
      ),
    ],
  );
  ref
    ..listen(
      startupFlowProvider.select((s) => s.step),
      (_, _) => router.refresh(),
    )
    ..onDispose(router.dispose);
  return router;
}

/// A start-up page: swapped in place (no slide), as before go_router.
GoRoute _gate(String path, Widget page) => GoRoute(
  path: path,
  pageBuilder: (context, state) => NoTransitionPage(child: page),
);

/// Home, with the saved home county and the Supabase board when
/// configured.
class _MapTab extends ConsumerWidget {
  const _MapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeCounty = ref.watch(
      startupFlowProvider.select((s) => s.homeCounty),
    );
    return MapHomeScreen(
      homeCounty: homeCounty,
      mapboxAccessToken: ref.watch(appConfigProvider).mapboxAccessToken,
      onOpenCounty: DetailRoutes.openCounty,
      onOpenPlace: DetailRoutes.openPlace,
      onRoute: DetailRoutes.openDirections,
      onSeeAllUnclaimed: DetailRoutes.openAllUnclaimed,
      loader: AppSupabase.isInitialized
          ? MapHomeBoardLoader(
              repository: SupabaseMapHomeRepository(AppSupabase.client),
            )
          : const MapHomeBoardLoader(),
    );
  }
}
