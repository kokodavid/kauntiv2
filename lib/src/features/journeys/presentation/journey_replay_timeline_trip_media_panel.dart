part of 'journey_replay_timeline.dart';

/// The Trip's album. Photos taken during the Trip also sit on the replay
/// timeline; photos added by hand have no real capture time, so they stay
/// here under "Other photos" and never interrupt the route replay.
class _TripMediaPanel extends StatelessWidget {
  const _TripMediaPanel({
    required this.media,
    required this.mediaLoading,
    required this.addingPhotos,
    required this.onAddPhotos,
    required this.onFindPhotos,
    required this.onDeletePhoto,
  });

  final List<JourneyMediaItem> media;
  final bool mediaLoading;
  final bool addingPhotos;
  final VoidCallback onAddPhotos;
  final VoidCallback onFindPhotos;
  final Future<bool> Function(BuildContext, JourneyMediaItem) onDeletePhoto;

  @override
  Widget build(BuildContext context) {
    final onTimeline = media.onTimeline;
    final other = media.albumOnly;
    final count = media.length;
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
                if (mediaLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
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
              mediaLoading
                  ? 'Loading your Trip media...'
                  : count == 0
                  ? 'Add photos from your gallery or find ones from this trip.'
                  : 'Photos taken during the Trip also appear on its timeline.',
              style: AppTypeScale.small.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
            if (!mediaLoading && onTimeline.isNotEmpty)
              _TripMediaGroup(
                label: other.isEmpty ? null : 'On the timeline',
                items: onTimeline,
                onDeletePhoto: onDeletePhoto,
              ),
            if (!mediaLoading && other.isNotEmpty)
              _TripMediaGroup(
                label: 'Other photos',
                caption: 'Kept in this album, not placed on the timeline.',
                items: other,
                onDeletePhoto: onDeletePhoto,
              ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: addingPhotos || mediaLoading ? null : onAddPhotos,
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
                  onPressed: addingPhotos || mediaLoading ? null : onFindPhotos,
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

/// A labelled row of photos. [label] is null when the panel has only one
/// group, so a lone row carries no heading.
class _TripMediaGroup extends StatelessWidget {
  const _TripMediaGroup({
    required this.items,
    required this.onDeletePhoto,
    this.label,
    this.caption,
  });

  final List<JourneyMediaItem> items;
  final Future<bool> Function(BuildContext, JourneyMediaItem) onDeletePhoto;
  final String? label;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Text(
              label!,
              style: AppTypeScale.small.copyWith(fontWeight: FontWeight.w700),
            ),
          if (caption != null)
            Text(
              caption!,
              style: AppTypeScale.small.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          if (label != null || caption != null) const SizedBox(height: 8),
          SizedBox(
            height: _TripMediaThumbnail.size,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => _TripMediaThumbnail(
                item: items[index],
                onDeletePhoto: onDeletePhoto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripMediaThumbnail extends StatelessWidget {
  const _TripMediaThumbnail({
    required this.item,
    required this.onDeletePhoto,
  });

  static const size = 72.0;

  final JourneyMediaItem item;
  final Future<bool> Function(BuildContext, JourneyMediaItem) onDeletePhoto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              openJourneyPhoto(context, item, onDelete: onDeletePhoto),
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: appNetworkImage(
                  item.url,
                  cacheKey: item.id,
                  cacheWidth: 240,
                ),
                fit: BoxFit.cover,
                onError: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );
  }
}
