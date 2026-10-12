import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/domain/app_feature_flags.dart';
import '../core/domain/connectivity_state.dart';
import '../core/services/connectivity_provider.dart';
import '../core/services/offline_screen_presence.dart';
import '../core/widgets/app_bottom_nav.dart';
import '../core/widgets/connectivity_lifecycle.dart';
import '../core/widgets/offline_banner.dart';
import '../design/app_colors.dart';
import '../features/detection/application/visit_sync.dart';
import '../features/detection/presentation/detection_lifecycle.dart';
import '../features/journeys/presentation/journey_active_banner.dart';
import '../features/journeys/presentation/journey_sync_lifecycle.dart';
import '../features/onboarding/application/startup_flow.dart';
import '../features/profile/application/public_profile_providers.dart';
import 'app_routes.dart';
import 'detail_routes.dart';

/// The root tab shell once onboarding is done (v1 `AppShell` parity): one
/// [AppBottomNav] floating over the live tabs. The tabs are go_router
/// branches ([StatefulShellRoute.indexedStack]), so each keeps its own
/// navigation stack, scroll position and state, and is built lazily on
/// first visit. Detection and Journey recovery / upload retries run around
/// the whole shell.
///
/// Tabs without a branch aren't ported yet; picking one shows a short
/// "coming next" note instead of switching.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _select(BuildContext context, AppNavTab tab) {
    final index = AppRoutes.tabs.indexOf(tab);
    if (index < 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('This tab is coming next.')),
        );
      return;
    }
    if (index == navigationShell.currentIndex) return;
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeCounty = ref.watch(
      startupFlowProvider.select((s) => s.homeCounty),
    );
    // Back online: catch the app up (queued visits upload), then let the
    // banner say "Up to date" and leave.
    ref.listen(connectivityProvider.select((s) => s.status), (prev, next) {
      if (next != ConnectivityStatus.reconnecting) return;
      unawaited(Future<void>(() async {
        try {
          await ref.read(visitSyncProvider.notifier).drain();
        } on Object {
          // Queued visits retry on their own schedule.
        }
        // Profile fell back to its saved copy while offline; reload it.
        ref.invalidate(myPublicProfileProvider);
        ref.read(connectivityProvider.notifier).markSynced();
      }));
    });
    final bannerShown =
        ref.watch(connectivityProvider.select((s) => s.showsBanner)) &&
        !ref.watch(offlineBannerSuppressedProvider);
    return ConnectivityLifecycle(
      child: DetectionLifecycle(
      homeCountyCode: homeCounty?.code,
      onOpenCounty: DetailRoutes.openCounty,
      onOpenPlace: DetailRoutes.openPlace,
      child: JourneySyncLifecycle(
        child: Scaffold(
          backgroundColor: AppColors.pageBackground,
          // A Stack, not a Column: the glass nav needs the active tab's
          // content underneath it to float over and blur.
          body: Stack(
            children: [
              // The offline pill takes the top 44 px while it shows, once,
              // on the same curve it enters on.
              Positioned.fill(
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(
                    top: bannerShown ? OfflineBanner.height : 0,
                  ),
                  child: navigationShell,
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top,
                left: 0,
                right: 0,
                height: OfflineBanner.height,
                child: const OfflineBanner(),
              ),
              // Home and Trips show the Trip in progress themselves.
              if (AppFeatureFlags.journeys &&
                  AppRoutes.tabs[navigationShell.currentIndex] !=
                      AppNavTab.journeys &&
                  AppRoutes.tabs[navigationShell.currentIndex] != AppNavTab.map)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 96,
                  child: Center(
                    child: JourneyActiveBanner(
                      onTap: () => context.push(AppRoutes.journeyRecording),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppBottomNav(
                  selected: AppRoutes.tabs[navigationShell.currentIndex],
                  onSelect: (tab) => _select(context, tab),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
