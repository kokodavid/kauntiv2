part of 'journey_replay_timeline.dart';

/// What the timeline shows in place of a moment list when a Trip has
/// none: start and end are always known from GPS, so they're always
/// shown (Claude-Design "2a" reference), with a card in the gap between
/// them offering to fill it in - either the camera-roll auto-match
/// (Claude-Design "2b") once photos are found, or the plain "Add photos"
/// / "Add note" pair as the fallback.
class _EmptyTimelineBody extends StatelessWidget {
  const _EmptyTimelineBody({
    required this.loading,
    required this.startedAt,
    required this.endedAt,
    required this.startCounty,
    required this.endCounty,
    required this.addingPhotos,
    required this.onAddPhotosManually,
    required this.cameraRoll,
    required this.onFindPhotos,
    required this.onAddAllMatches,
    required this.onChooseMatches,
  });

  final bool loading;
  final DateTime startedAt;
  final DateTime endedAt;
  final String? startCounty;
  final String? endCounty;
  final bool addingPhotos;
  final VoidCallback onAddPhotosManually;
  final _CameraRollScan cameraRoll;
  final VoidCallback onFindPhotos;
  final VoidCallback onAddAllMatches;
  final VoidCallback onChooseMatches;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: AppProgressIndicator(color: AppColors.accent, radius: 10),
        ),
      );
    }
    final startAt = TimeOfDay.fromDateTime(startedAt.toLocal()).format(context);
    final endAt = TimeOfDay.fromDateTime(endedAt.toLocal()).format(context);
    final titleStyle = AppTypeScale.itemTitle.copyWith(
      fontWeight: FontWeight.w600,
    );
    final card = cameraRoll.status == _CameraRollStatus.matchesFound
        ? _CameraRollMatchCard(
            matches: cameraRoll.matches,
            busy: addingPhotos,
            onAddAll: onAddAllMatches,
            onChoose: onChooseMatches,
          )
        : _AddMomentsCard(
            title: 'No moments on this trip',
            message: 'The replay pauses at each photo or note.',
            onAddPhotos: onAddPhotosManually,
            addingPhotos: addingPhotos,
            showFindPhotosLink: cameraRoll.status == _CameraRollStatus.noAccess,
            onFindPhotos: onFindPhotos,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.accent,
                    child: Icon(
                      Icons.trip_origin,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.cardBorder,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        startAt,
                        style: AppTypeScale.meta.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        startCounty == null
                            ? 'Trip started'
                            : 'Started in $startCounty',
                        style: titleStyle,
                      ),
                      const SizedBox(height: 8),
                      card,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.buttonForeground,
              child: Icon(Icons.flag, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      endAt,
                      style: AppTypeScale.meta.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      endCounty == null
                          ? 'Trip ended'
                          : 'Arrived in $endCounty',
                      style: titleStyle,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
