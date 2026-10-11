part of 'journey_replay_timeline.dart';

/// One horizontally scrolling row: timeline photos, a divider, then the
/// album-only ones. A group's label shows only when both groups exist.
class _TripMediaRow extends StatelessWidget {
  const _TripMediaRow({
    required this.onTimeline,
    required this.other,
    required this.onDeletePhoto,
  });

  final List<JourneyMediaItem> onTimeline;
  final List<JourneyMediaItem> other;
  final Future<bool> Function(BuildContext, JourneyMediaItem) onDeletePhoto;

  @override
  Widget build(BuildContext context) {
    final both = onTimeline.isNotEmpty && other.isNotEmpty;
    // One swipe order for the viewer: exactly what the row shows.
    final all = [...onTimeline, ...other];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (onTimeline.isNotEmpty)
            _TripMediaGroup(
              label: both ? 'On the timeline' : null,
              items: onTimeline,
              all: all,
              offset: 0,
              onDeletePhoto: onDeletePhoto,
            ),
          if (both)
            Container(
              width: 1,
              height: _TripMediaThumbnail.size,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: AppColors.cardBorder,
            ),
          if (other.isNotEmpty)
            _TripMediaGroup(
              label: both ? 'Other photos' : null,
              items: other,
              all: all,
              offset: onTimeline.length,
              onDeletePhoto: onDeletePhoto,
            ),
        ],
      ),
    );
  }
}

class _TripMediaGroup extends StatelessWidget {
  const _TripMediaGroup({
    required this.items,
    required this.all,
    required this.offset,
    required this.onDeletePhoto,
    this.label,
  });

  final List<JourneyMediaItem> items;

  /// Every photo in the row, and where [items] starts within it.
  final List<JourneyMediaItem> all;
  final int offset;
  final Future<bool> Function(BuildContext, JourneyMediaItem) onDeletePhoto;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypeScale.small.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              _TripMediaThumbnail(
                item: items[i],
                onOpen: () => openJourneyPhotos(
                  context,
                  all,
                  initialIndex: offset + i,
                  onDelete: onDeletePhoto,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TripMediaThumbnail extends StatelessWidget {
  const _TripMediaThumbnail({required this.item, required this.onOpen});

  static const size = 84.0;

  final JourneyMediaItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              image: DecorationImage(
                image: appNetworkImage(
                  item.url,
                  cacheKey: item.id,
                  cacheWidth: 280,
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
