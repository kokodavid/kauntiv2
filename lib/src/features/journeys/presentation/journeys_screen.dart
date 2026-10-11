import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/offline_screen.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/journey_history.dart';
import '../application/journey_recorder.dart';
import '../application/journey_sync.dart';
import 'journey_hero_stats.dart';
import 'journey_history_section.dart';
import 'journey_live_card.dart';
import 'journey_recording_screen.dart';
import 'journey_start_card.dart';

/// The Journeys tab: the Journey in progress (or Start), then history.
class JourneysScreen extends ConsumerWidget {
  const JourneysScreen({
    super.key,
    this.onOpenJourney,
    this.onOpenSettings,
    this.onOpenRecording,
  });

  final OpenJourney? onOpenJourney;
  final OpenAppSettings? onOpenSettings;

  /// The full-screen map for the Journey in progress.
  final OpenJourneyRecording? onOpenRecording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(journeyRecorderProvider) != null;
    final history = ref.watch(journeyHistoryListProvider).value;
    // Offline with no Trip on this phone: say so, rather than offering a
    // Start that can't run and "no Trips yet" that isn't true.
    if (!active &&
        history != null &&
        history.cloudUnavailable &&
        history.journeys.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text('Trips', style: AppTextStyles.headingForeground),
              ),
              Expanded(
                child: OfflineScreen(
                  key: const Key('trips-offline-screen'),
                  message:
                      'Your Trips load from the internet, and a new Trip '
                      'needs a connection to start. Check your data or '
                      'Wi‑Fi, then try again.',
                  onRetry: () => ref.invalidate(journeyHistoryListProvider),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(journeySyncProvider.notifier).drain();
            ref.invalidate(journeyHistoryListProvider);
          },
          child: ListView(
            // Room for the floating tab bar.
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              const Text('Trips', style: AppTextStyles.headingForeground),
              const SizedBox(height: 16),
              const JourneyHeroStats(),
              const SizedBox(height: 16),
              if (active)
                JourneyLiveCard(onOpenMap: onOpenRecording)
              else
                JourneyStartCard(
                  onOpenSettings: onOpenSettings,
                  onStarted: onOpenRecording,
                ),
              const SizedBox(height: 24),
              JourneyHistorySection(onOpen: onOpenJourney),
            ],
          ),
        ),
      ),
    );
  }
}
