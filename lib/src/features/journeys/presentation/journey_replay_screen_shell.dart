part of 'journey_replay_screen.dart';

/// A past Journey as a scrollable story: the map at the top sets the
/// scene, a timeline of its key moments tells it below, and a floating
/// transport bar drives the replay through both.
class JourneyReplayScreen extends ConsumerWidget {
  const JourneyReplayScreen({
    super.key,
    required this.journeyId,
    this.onOpenCounty,
    this.shareExtrasBuilder,
  });

  final String journeyId;
  final ValueChanged<int>? onOpenCounty;

  /// Extra content for the Share trip sheet, supplied by the app so this
  /// feature never depends on another feature's screens.
  final TripShareExtrasBuilder? shareExtrasBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(journeyDetailProvider(journeyId));
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
              momentsLoading: momentsLoading,
              onOpenCounty: onOpenCounty,
              shareExtrasBuilder: shareExtrasBuilder,
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: switch (detail) {
                    AsyncValue(:final error?) => JourneyReplayMessage(
                      text: error is JourneyNotFound
                          ? 'This Trip was deleted.'
                          : "Couldn't load this Trip. Check your "
                                'connection.',
                      onRetry: error is JourneyNotFound
                          ? null
                          : () => ref.invalidate(
                              journeyDetailProvider(journeyId),
                            ),
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
    required this.momentsLoading,
    this.onOpenCounty,
    this.shareExtrasBuilder,
  });

  final JourneySummary summary;
  final JourneyRoute route;
  final List<JourneyMoment> moments;

  /// Forwarded to [JourneyReplayTimeline] so it can show a loading
  /// indicator instead of "No key moments on this Trip yet." while
  /// `journeyMomentsProvider` is still computing its first value.
  final bool momentsLoading;
  final ValueChanged<int>? onOpenCounty;
  final TripShareExtrasBuilder? shareExtrasBuilder;

  @override
  State<_Player> createState() => _PlayerState();
}
