part of 'journey_replay_screen.dart';

/// A past Journey as a scrollable story: the map at the top sets the
/// scene, a timeline of its key moments tells it below, and a floating
/// transport bar drives the replay through both.
class JourneyReplayScreen extends ConsumerWidget {
  const JourneyReplayScreen({
    super.key,
    required this.journeyId,
    this.onOpenCounty,
  });

  final String journeyId;
  final ValueChanged<int>? onOpenCounty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(journeyDetailProvider(journeyId));
    final mediaAsync = ref.watch(journeyMediaProvider(journeyId));
    final media = mediaAsync.value ?? const <JourneyMediaItem>[];
    final mediaLoading = mediaAsync.isLoading && !mediaAsync.hasValue;
    final momentsAsync = ref.watch(journeyMomentsProvider(journeyId));
    final moments = momentsAsync.value;
    // True only while moments has never resolved yet - a refresh that
    // already has a cached value (isLoading alongside hasValue) shouldn't
    // re-trigger the loader, only this Trip's very first computation.
    final momentsLoading = momentsAsync.isLoading && !momentsAsync.hasValue;
    final value = detail.value;
    final route = value?.route;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: route != null && route.pointCount > 1
          ? _Player(
              summary: value!.summary,
              route: route,
              moments: moments ?? const [],
              media: media,
              mediaLoading: mediaLoading,
              momentsLoading: momentsLoading,
              onOpenCounty: onOpenCounty,
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: switch (detail) {
                    AsyncValue(:final error?) when error is JourneyNotFound =>
                      const JourneyReplayMessage(
                        text: 'This Trip was deleted.',
                      ),
                    AsyncValue(hasError: true) => OfflineScreen(
                      showHint: false,
                      message:
                          'This Trip needs a connection to open. Check your '
                          'data or Wi‑Fi, then try again.',
                      onRetry: () =>
                          ref.invalidate(journeyDetailProvider(journeyId)),
                    ),
                    AsyncValue(hasValue: true) => const JourneyReplayMessage(
                      text:
                          'Not enough route points were recorded to '
                          'show this Trip.',
                    ),
                    _ => const CircularProgressIndicator(strokeWidth: 2),
                  },
                ),
                JourneyMapButton(
                  alignment: Alignment.topLeft,
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Close replay',
                  icon: Icons.close,
                ),
              ],
            ),
    );
  }
}

class _Player extends StatefulWidget {
  const _Player({
    required this.summary,
    required this.route,
    required this.moments,
    required this.media,
    required this.mediaLoading,
    required this.momentsLoading,
    this.onOpenCounty,
  });

  final JourneySummary summary;
  final JourneyRoute route;
  final List<JourneyMoment> moments;
  final List<JourneyMediaItem> media;
  final bool mediaLoading;

  /// Forwarded to [JourneyReplayTimeline] so it can show a loading
  /// indicator instead of "No key moments on this Trip yet." while
  /// `journeyMomentsProvider` is still computing its first value.
  final bool momentsLoading;
  final ValueChanged<int>? onOpenCounty;

  @override
  State<_Player> createState() => _PlayerState();
}
