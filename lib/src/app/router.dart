import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/domain/app_feature_flags.dart';
import '../core/services/app_config_provider.dart';
import '../core/services/last_screen.dart';
import '../core/services/location_diagnostics.dart';
import '../features/app_version/application/app_update_providers.dart';
import '../features/app_version/presentation/update_settings_row.dart';
import '../features/badges/presentation/badges_screen.dart';
import '../features/discover/presentation/county_detail_screen.dart';
import '../features/discover/presentation/explore_screen.dart';
import '../features/discover/presentation/place_detail_screen.dart';
import '../features/feedback/presentation/feedback_form_screen.dart';
import '../features/feedback/presentation/feedback_reports_screen.dart';
import '../features/journeys/application/journey_recorder.dart';
import '../features/journeys/presentation/journey_recording_screen.dart';
import '../features/journeys/presentation/journey_replay_screen.dart';
import '../features/journeys/presentation/journeys_screen.dart';
import '../features/location_diagnostics/presentation/location_diagnostics_screen.dart';
import '../features/notifications/presentation/push_lifecycle.dart';
import '../features/notifications/presentation/trip_alert_lifecycle.dart';
import '../features/onboarding/application/startup_flow.dart';
import '../features/profile/presentation/interests_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/settings_screen.dart';
import '../features/trip_planner/presentation/saved_plans_screen.dart';
import '../features/trip_planner/presentation/trip_plan_section.dart';
import '../features/trip_planner/presentation/trip_start_button.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'app_update_routes.dart';
import 'detail_routes.dart';
import 'journey_place_routes.dart';
import 'place_photos_routes.dart';
import 'push_routes.dart';
import 'router_map_tab.dart';
import 'startup_pages.dart';

part 'router.g.dart';

/// The app's router (architecture §5). Start-up gating is one redirect on
/// [StartupFlow]'s step; the tabs are a [StatefulShellRoute]; County and
/// Place Detail push over the shell on the root navigator.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final journeyActive =
          AppFeatureFlags.journeys && ref.read(journeyRecorderProvider) != null;
      final update = ref.read(appUpdateControllerProvider);
      return AppRoutes.redirect(
        ref.read(startupFlowProvider).step,
        state.matchedLocation,
        updateRequired: update?.required == true && !journeyActive,
      );
    },
    routes: [
      _gate(AppRoutes.splash, const StartupSplashPage()),
      _gate(AppRoutes.signIn, const StartupSignInPage()),
      _gate(AppRoutes.homeCounty, const StartupHomeCountyPage()),
      _gate(AppRoutes.preferences, const StartupPreferencesPage()),
      _gate(AppRoutes.permission, const StartupPermissionPage()),
      _gate(AppRoutes.notifications, const StartupNotificationsPage()),
      ...appUpdateRoutes(),
      StatefulShellRoute.indexedStack(
        // Swapped in place like the gates, not slid in.
        pageBuilder: (context, state, shell) => NoTransitionPage(
          // Push runs for the onboarded app only: the shell is not built
          // until start-up is done.
          child: PushLifecycle(
            onOpen: PushRoutes.open,
            child: TripAlertLifecycle(child: AppShell(navigationShell: shell)),
          ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.map,
                builder: (context, state) => const MapTab(),
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
            onOpenFeedback: () => context.push(AppRoutes.feedback),
            photosEntry: PlacePhotosRoutes.profileEntry,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.myPhotos,
        builder: (context, state) => PlacePhotosRoutes.myPhotos(context),
      ),
      GoRoute(
        path: AppRoutes.feedback,
        builder: (context, state) => FeedbackFormScreen(
          onOpenReports: () => context.push(AppRoutes.feedbackReports),
        ),
      ),
      GoRoute(
        path: AppRoutes.feedbackReports,
        builder: (context, state) =>
            FeedbackReportsScreen(onSendFeedback: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.interests,
        builder: (context, state) => const InterestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        // NoTransitionPage for the same reason as Profile above: sign-out
        // (and delete-account) redirect here mid-stack, and an animated
        // transition would expose a frame of this screen's own
        // already-signed-out state while it slides away.
        pageBuilder: (context, state) => NoTransitionPage(
          child: SettingsScreen(
            topSlot: const UpdateSettingsRow(),
            onOpenLocationSettings: DetailRoutes.openAppSettings,
            onOpenInterests: () => context.push(AppRoutes.interests),
            onOpenLocationDiagnostics:
                LocationDiagnostics.enabledFor(
                  isDev: ref.read(appConfigProvider).isDev,
                )
                ? () => context.push(AppRoutes.locationDiagnostics)
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
        path: AppRoutes.savedPlans,
        builder: (context, state) => SavedPlansScreen(
          onOpenPlace: (context, id) => context.push(AppRoutes.place(id)),
          onBack: () => Navigator.of(context).maybePop(),
        ),
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
          gettingThere: (context, place) => TripPlanSection(
            placeId: place.id,
            placeName: place.title,
            latitude: place.latitude!,
            longitude: place.longitude!,
            onStart: (context, stops) =>
                JourneyPlaceRoutes.startPlanned(context, place, stops),
            onOpenPlace: DetailRoutes.openPlace,
            onDirections: (stops) async {
              await DetailRoutes.actions!.openDirections(
                place,
                waypoints: [for (final s in stops) '${s.lat},${s.lng}'],
              );
            },
          ),
          startButton: (context, place) => TripStartButton(
            placeId: place.id,
            latitude: place.latitude!,
            longitude: place.longitude!,
            onStart: (context, stops) =>
                JourneyPlaceRoutes.startPlanned(context, place, stops),
          ),
          photos: PlacePhotosRoutes.placeSection,
        ),
      ),
    ],
  );
  // Remember the screen the user is on so a bug report can say where it
  // happened. Deferred a microtask: the router notifies mid-navigation.
  void rememberScreen() {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    unawaited(
      Future<void>.microtask(() {
        if (ref.mounted) ref.read(lastScreenProvider.notifier).record(path);
      }),
    );
  }

  router.routerDelegate.addListener(rememberScreen);
  ref.listen(
    startupFlowProvider.select((s) => s.step),
    (_, _) => router.refresh(),
  );
  ref.listen(appUpdateControllerProvider, (_, _) => router.refresh());
  if (AppFeatureFlags.journeys) {
    ref.listen(journeyRecorderProvider, (_, _) => router.refresh());
  }
  ref.onDispose(() {
    router.routerDelegate.removeListener(rememberScreen);
    router.dispose();
  });
  return router;
}

/// A start-up page: swapped in place (no slide), as before go_router.
GoRoute _gate(String path, Widget page) => GoRoute(
  path: path,
  pageBuilder: (context, state) => NoTransitionPage(child: page),
);
