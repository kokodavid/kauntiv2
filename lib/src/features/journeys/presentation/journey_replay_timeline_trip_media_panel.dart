part of 'journey_replay_timeline.dart';

/// A stable entry point for photos on every replay with a timeline. The
/// timeline still owns their chronological placement; this panel makes adding
/// and revisiting media discoverable after the first photo has been added.
class _TripMediaPanel extends StatelessWidget {
  const _TripMediaPanel({
    required this.photoMoments,
    required this.addingPhotos,
    required this.onAddPhotos,
    required this.onFindPhotos,
    required this.onDeletePhoto,
  });

  final List<JourneyMoment> photoMoments;
  final bool addingPhotos;
  final VoidCallback onAddPhotos;
  final VoidCallback onFindPhotos;
  final Future<bool> Function(BuildContext, JourneyMediaItem) onDeletePhoto;

  @override
  Widget build(BuildContext context) {
    final visiblePhotos = photoMoments.take(3).toList(growable: false);
    final count = photoMoments.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trip media',
                    style: AppTypeScale.itemTitle.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  count == 1 ? '1 photo' : '$count photos',
                  style: AppTypeScale.small.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              count == 0
                  ? 'Add photos from your gallery or find ones from this trip.'
                  : 'Tap a photo to review it on the timeline or remove it.',
              style: AppTypeScale.small.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
            if (visiblePhotos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 72,
                child: Row(
                  children: [
                    for (final moment in visiblePhotos)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _TripMediaThumbnail(
                            moment: moment,
                            onDeletePhoto: onDeletePhoto,
                          ),
                        ),
                      ),
                    if (count > visiblePhotos.length)
                      _TripMediaMoreCount(count: count - visiblePhotos.length),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: addingPhotos ? null : onAddPhotos,
                  icon: addingPhotos
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: Text(addingPhotos ? 'Adding...' : 'Add photos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: addingPhotos ? null : onFindPhotos,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Find trip photos'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TripMediaThumbnail extends StatelessWidget {
  const _TripMediaThumbnail({
    required this.moment,
    required this.onDeletePhoto,
  });

  final JourneyMoment moment;
  final Future<bool> Function(BuildContext, JourneyMediaItem) onDeletePhoto;

  @override
  Widget build(BuildContext context) {
    final photo = moment.photo!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openJourneyPhoto(
          context,
          photo,
          onDelete: onDeletePhoto,
        ),
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: appNetworkImage(
                photo.url,
                cacheKey: photo.id,
                cacheWidth: 240,
              ),
              fit: BoxFit.cover,
              onError: (_, __) {},
            ),
          ),
        ),
      ),
    );
  }
}

class _TripMediaMoreCount extends StatelessWidget {
  const _TripMediaMoreCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.lockedFill,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      '+$count',
      style: AppTypeScale.itemTitle.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}
