part of 'journey_replay_timeline.dart';

/// The lighter-weight sibling of [_EmptyTimelineBody]: for a Trip that
/// already has other moments (stops, crossings, an elevation peak...) but
/// no photos yet, there's a real timeline to keep showing, so this is
/// appended after it rather than replacing it with the full start/end-pin
/// skeleton. Shares the same camera-roll match card and "add photos"
/// fallback card as the fully-empty case, just without the pins.
class _InlineCameraRollSuggestion extends StatelessWidget {
  const _InlineCameraRollSuggestion({
    required this.photoMoments,
    required this.cameraRoll,
    required this.addingPhotos,
    required this.onAddPhotos,
    required this.onFindPhotos,
    required this.onAddAllMatches,
    required this.onChooseMatches,
    required this.onDeletePhoto,
  });

  final List<JourneyMoment> photoMoments;
  final _CameraRollScan cameraRoll;
  final bool addingPhotos;
  final VoidCallback onAddPhotos;
  final VoidCallback onFindPhotos;
  final VoidCallback onAddAllMatches;
  final VoidCallback onChooseMatches;
  final Future<bool> Function(BuildContext, JourneyMediaItem) onDeletePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TripMediaPanel(
          photoMoments: photoMoments,
          addingPhotos: addingPhotos,
          onAddPhotos: onAddPhotos,
          onFindPhotos: onFindPhotos,
          onDeletePhoto: onDeletePhoto,
        ),
        if (cameraRoll.status == _CameraRollStatus.matchesFound) ...[
          const SizedBox(height: 16),
          _CameraRollMatchCard(
            matches: cameraRoll.matches,
            busy: addingPhotos,
            onAddAll: onAddAllMatches,
            onChoose: onChooseMatches,
          ),
        ],
      ],
    );
  }
}
