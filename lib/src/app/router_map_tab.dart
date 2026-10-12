import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/domain/app_feature_flags.dart';
import '../core/services/app_config_provider.dart';
import '../features/detection/application/detection_providers.dart';
import '../features/detection/data/detection_repository.dart';
import '../features/detection/presentation/notifications_prompt_card.dart';
import '../features/journeys/application/device_motion.dart';
import '../features/journeys/application/journey_recorder.dart';
import '../features/journeys/domain/journey_recording.dart';
import '../features/journeys/domain/motion_rules.dart';
import '../features/journeys/presentation/journey_recording_controls.dart';
import '../features/journeys/presentation/journey_start_card.dart';
import '../features/map_home/application/map_home_board_loader.dart';
import '../features/map_home/data/offline_map_home_repository.dart';
import '../features/map_home/data/supabase_map_home_repository.dart';
import '../features/map_home/presentation/map_home_board_sheet.dart'
    show defaultRecordTripCardHeight;
import '../features/map_home/presentation/map_home_screen.dart';
import '../features/onboarding/application/startup_flow.dart';
import '../features/profile/presentation/interests_prompt_card.dart';
import '../features/trip_planner/presentation/saved_plans_home_section.dart';
import '../services/app_supabase.dart';
import 'app_routes.dart';
import 'detail_routes.dart';
import 'journey_place_routes.dart';

/// Home tab wiring belongs beside the router, while its UI stays in Map Home.
class MapTab extends ConsumerWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeCounty = ref.watch(
      startupFlowProvider.select((s) => s.homeCounty),
    );
    final isTripRecording = ref.watch(
      journeyRecorderProvider.select(
        (s) => s?.recording.phase == JourneyRecordingPhase.recording,
      ),
    );
    final hasTrip =
        AppFeatureFlags.journeys &&
        ref.watch(journeyRecorderProvider.select((s) => s != null));
    final isMoving =
        AppFeatureFlags.journeys &&
        !hasTrip &&
        TickerMode.valuesOf(context).enabled &&
        ref.watch(deviceMotionProvider).value == MotionState.moving;
    return MapHomeScreen(
      homeCounty: homeCounty,
      // The card lives in the profile feature, so the app layer hands it to
      // Home rather than Home importing it.
      topCard: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NotificationsPromptCard(
            onOpenSettings: DetailRoutes.openAppSettings,
          ),
          InterestsPromptCard(onPick: () => context.push(AppRoutes.interests)),
        ],
      ),
      isTripRecording: isTripRecording,
      savedPlans: DetailRoutes.openPlace == null
          ? null
          : SavedPlansHomeSection(
              onOpenPlace: DetailRoutes.openPlace!,
              onSeeAll: () => context.push(AppRoutes.savedPlans),
            ),
      recordTripCardHeight: hasTrip ? 84 : defaultRecordTripCardHeight,
      recordTripCard: hasTrip
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push(AppRoutes.journeyRecording),
              child: const JourneyRecordingControls(
                compact: true,
                onOpenSettings: DetailRoutes.openAppSettings,
              ),
            )
          : isMoving
          ? JourneyStartCard(
              onOpenSettings: DetailRoutes.openAppSettings,
              onStarted: (context) => context.push(AppRoutes.journeyRecording),
            )
          : null,
      onStartTrip: AppFeatureFlags.journeys
          ? () => context.go(AppRoutes.journeys)
          : null,
      mapboxAccessToken: ref.watch(appConfigProvider).mapboxAccessToken,
      onOpenCounty: DetailRoutes.openCounty,
      onOpenPlace: DetailRoutes.openPlace,
      onRoute: DetailRoutes.openDirections,
      onPlaceRoute: JourneyPlaceRoutes.openMapPlace,
      onPromotedPlaceRoute: JourneyPlaceRoutes.openPromotion,
      onSeeAllUnclaimed: DetailRoutes.openAllUnclaimed,
      onOpenProfile: () => context.push(AppRoutes.profile),
      loader: AppSupabase.isInitialized
          ? MapHomeBoardLoader(
              // Saves each good board and falls back to it, plus visits
              // detected on this phone but not synced, when offline.
              repository: OfflineMapHomeRepository(
                inner: SupabaseMapHomeRepository(AppSupabase.client),
                userId: () => AppSupabase.client.auth.currentUser?.id,
                pendingCounties: ref
                    .read(detectionRepositoryProvider)
                    .pendingCountyCodes,
              ),
            )
          : const MapHomeBoardLoader(),
    );
  }
}
