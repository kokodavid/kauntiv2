import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/journey_history.dart';
import '../application/journey_recorder.dart';
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
