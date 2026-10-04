import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/domain/app_feature_flags.dart';
import '../core/services/app_config_provider.dart';
import '../core/services/location_diagnostics.dart';
import '../features/badges/presentation/badges_screen.dart';
import '../features/discover/presentation/county_detail_screen.dart';
import '../features/discover/presentation/explore_screen.dart';
import '../features/discover/presentation/place_detail_screen.dart';
import '../features/journeys/domain/journey_transport_mode.dart';
import '../features/journeys/presentation/journey_recording_screen.dart';
import '../features/journeys/presentation/journey_replay_screen.dart';
import '../features/journeys/presentation/journeys_screen.dart';
import '../features/location_diagnostics/presentation/location_diagnostics_screen.dart';
import '../features/map_home/application/map_home_board_loader.dart';
import '../features/map_home/data/supabase_map_home_repository.dart';
import '../features/map_home/presentation/map_home_screen.dart';
import '../features/onboarding/application/startup_flow.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/settings_screen.dart';
import '../features/public_trips/presentation/public_trip_defaults_screen.dart';
import '../features/public_trips/presentation/public_trip_entry_tile.dart';
import '../features/public_trips/presentation/public_trip_review_screen.dart';
import '../features/public_trips/presentation/public_trip_screen.dart';
import '../features/public_trips/presentation/public_trips_home_row.dart';
import '../services/app_supabase.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'detail_routes.dart';
import 'journey_place_routes.dart';
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
                path: AppRoutes.badges,
                builder: (context, state) => BadgesScreen(
                  onOpenCounty: DetailRoutes.openCounty,
                  onOpenPlace: DetailRoutes.openPlace,
                ),
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
          if (AppFeatureFlags.journeys)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.journeys,
                  builder: (context, state) => JourneysScreen(
                    onOpenJourney: (context, id) =>
                        context.push(AppRoutes.journey(id)),
                    onOpenSettings: DetailRoutes.openAppSettings,
                    onOpenRecording: (context) =>
                        context.push(AppRoutes.journeyRecording),
                  ),
                ),
              ],
            ),
        ],
      ),
      if (AppFeatureFlags.journeys)
        GoRoute(
          path: AppRoutes.journeyRecording,
          builder: (context, state) => JourneyRecordingScreen(
            onOpenSettings: DetailRoutes.openAppSettings,
            onOpenPlace: DetailRoutes.openPlace,
            onRoute: DetailRoutes.openDirections,
            onPlaceRoute: JourneyPlaceRoutes.openMapPlace,
          ),
        ),
      if (AppFeatureFlags.journeys)
        GoRoute(
          path: '/journey/:id',
          builder: (context, state) => JourneyReplayScreen(
            journeyId: state.pathParameters['id']!,
            onOpenCounty: (code) =>
                DetailRoutes.openCounty?.call(context, code),
            shareExtrasBuilder: (sheetContext, summary) => PublicTripEntryTile(
              journeyId: summary.id,
              // Only a finished, uploaded Drive or Walk can be published.
              canPublish:
                  summary.isUploaded &&
                  (summary.transportMode == JourneyTransportMode.drive ||
                      summary.transportMode == JourneyTransportMode.walk),
              onOpen: () {
                Navigator.of(sheetContext).pop();
                if (context.mounted) {
                  unawaited(
                    context.push(AppRoutes.publicTripReview(summary.id)),
                  );
                }
              },
              onView: (publicationId) {
                Navigator.of(sheetContext).pop();
                if (context.mounted) {
                  unawaited(context.push(AppRoutes.publicTrip(publicationId)));
                }
              },
            ),
          ),
        ),
      if (AppFeatureFlags.journeys)
        GoRoute(
          path: '/journey/:id/public',
          builder: (context, state) => PublicTripReviewScreen(
            journeyId: state.pathParameters['id']!,
            onOpenDefaults: () => context.push(AppRoutes.publicTripDefaults),
          ),
        ),
      if (AppFeatureFlags.journeys)
        GoRoute(
          path: AppRoutes.publicTripDefaults,
          builder: (context, state) => const PublicTripDefaultsScreen(),
        ),
      GoRoute(
        path: '/public-trip/:id',
        builder: (context, state) => PublicTripScreen(
          publicationId: state.pathParameters['id']!,
          onOpenDirections: (lat, lng) =>
              unawaited(DetailRoutes.openDirections('$lat,$lng')),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        // NoTransitionPage: sign-out swaps straight to the Sign-In gate
        // (also swapped in place) via the redirect below. An animated
        // page transition here would spend its ~300ms showing this
        // route's own already-signed-out placeholder content mid-slide,
        // which is the "screen that appears before Sign-In" sign-out
        // used to flash.
        pageBuilder: (context, state) => NoTransitionPage(
          child: ProfileScreen(
            onOpenBadges: () => context.go(AppRoutes.badges),
            onOpenJourneys: AppFeatureFlags.journeys
                ? () => context.go(AppRoutes.journeys)
                : null,
            onOpenSettings: () => context.push(AppRoutes.settings),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        // NoTransitionPage for the same reason as Profile above: sign-out
        // (and delete-account) redirect here mid-stack, and an animated
        // transition would expose a frame of this screen's own
        // already-signed-out state while it slides away.
        pageBuilder: (context, state) => NoTransitionPage(
          child: SettingsScreen(
            onOpenLocationSettings: DetailRoutes.openAppSettings,
            onOpenLocationDiagnostics:
                LocationDiagnostics.enabledFor(
                  isDev: ref.read(appConfigProvider).isDev,
                )
                ? () => context.push(AppRoutes.locationDiagnostics)
                : null,
            onOpenPublicTripDefaults: AppFeatureFlags.journeys
                ? () => context.push(AppRoutes.publicTripDefaults)
                : null,
          ),
        ),
      ),
      if (LocationDiagnostics.enabledFor(
        isDev: ref.read(appConfigProvider).isDev,
      ))
        GoRoute(
          path: AppRoutes.locationDiagnostics,
          builder: (context, state) => const LocationDiagnosticsScreen(),
        ),
      GoRoute(
        path: '/county/:code',
        builder: (context, state) => CountyDetailScreen(
          countyCode: int.parse(state.pathParameters['code']!),
          actions: DetailRoutes.actions!,
          onOpenPlace: DetailRoutes.openPlace,
        ),
      ),
      GoRoute(
        path: '/place/:id',
        builder: (context, state) => PlaceDetailScreen(
          placeId: state.pathParameters['id']!,
          actions: DetailRoutes.actions!,
          onGetRoute: JourneyPlaceRoutes.open,
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
      onPlaceRoute: JourneyPlaceRoutes.openMapPlace,
      onPromotedPlaceRoute: JourneyPlaceRoutes.openPromotion,
      onSeeAllUnclaimed: DetailRoutes.openAllUnclaimed,
      onOpenProfile: () => context.push(AppRoutes.profile),
      sheetExtra: PublicTripsHomeRow(
        countyCode: homeCounty?.code,
        onOpenTrip: (id) => unawaited(context.push(AppRoutes.publicTrip(id))),
      ),
      loader: AppSupabase.isInitialized
          ? MapHomeBoardLoader(
              repository: SupabaseMapHomeRepository(AppSupabase.client),
            )
          : const MapHomeBoardLoader(),
    );
  }
}
