part of 'journey_replay_timeline.dart';

/// The Trip's album inside the bottom sheet: one row of photos (with
/// "On the timeline" / "Other photos" labels when both kinds exist) and a
/// header with Find and Add buttons. Photos taken during the Trip also sit
/// on the replay timeline; photos added by hand stay here only.
class _TripMediaSheetBody extends StatelessWidget {
  const _TripMediaSheetBody({
    required this.media,
    required this.mediaLoading,
    required this.addingPhotos,
    required this.limit,
    required this.onAddPhotos,
    required this.onFindPhotos,
    required this.onDeletePhoto,
  });

  final List<JourneyMediaItem> media;
  final bool mediaLoading;
  final bool addingPhotos;
  final JourneyMediaLimit? limit;
  final VoidCallback onAddPhotos;
  final VoidCallback onFindPhotos;
  final Future<bool> Function(BuildContext, JourneyMediaItem) onDeletePhoto;

  @override
  Widget build(BuildContext context) {
    final onTimeline = media.onTimeline;
    final other = media.albumOnly;
    final full = limit?.isFull(media.length) ?? false;
    final busy = addingPhotos || mediaLoading || full;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Trip media',
                      style: AppTypeScale.itemTitle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!mediaLoading && media.isNotEmpty)
                      Text(
                        limit?.usageLabel(media.length) ?? '${media.length}',
                        style: AppTypeScale.small.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              _TripMediaRoundButton(
                label: 'Find trip photos',
                icon: Icons.center_focus_strong_outlined,
                onPressed: busy ? null : onFindPhotos,
              ),
              const SizedBox(width: 8),
              _TripMediaRoundButton(
                label: 'Add photos',
                icon: addingPhotos ? null : Icons.add,
                filled: true,
                onPressed: busy ? null : onAddPhotos,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (mediaLoading)
          const _TripMediaSkeleton()
        else if (media.isEmpty)
          const _TripMediaEmpty()
        else ...[
          _TripMediaRow(
            onTimeline: onTimeline,
            other: other,
            onDeletePhoto: onDeletePhoto,
          ),
          if (full)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(
                limit!.fullMessage,
                style: AppTypeScale.small.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          if (onTimeline.isNotEmpty && other.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(
                'Other photos are kept in this album, not placed on the '
                'timeline.',
                style: AppTypeScale.small.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _TripMediaSkeleton extends StatelessWidget {
  const _TripMediaSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _TripMediaThumbnail.size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, _) => Container(
          width: _TripMediaThumbnail.size,
          decoration: BoxDecoration(
            color: AppColors.emptyTimelineCardBackground,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _TripMediaEmpty extends StatelessWidget {
  const _TripMediaEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              size: 22,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'No photos yet. ',
                    style: AppTypeScale.small.copyWith(
                      color: AppColors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text:
                        'Tap + to add from your gallery, or scan to find ones '
                        'taken during this Trip.',
                  ),
                ],
              ),
              style: AppTypeScale.small.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
