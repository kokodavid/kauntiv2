part of 'journey_replay_timeline.dart';

class _ThumbnailTile extends StatelessWidget {
  const _ThumbnailTile({required this.match});

  final CameraRollMatch match;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: FutureBuilder<Uint8List?>(
              future: match.asset.thumbnailDataWithSize(
                const ThumbnailSize.square(200),
              ),
              builder: (context, snapshot) {
                final bytes = snapshot.data;
                if (bytes == null) {
                  return const ColoredBox(color: AppColors.lockedFill);
                }
                return Image.memory(bytes, fit: BoxFit.cover);
              },
            ),
          ),
          // A read-only hint that this slot collapsed a burst - swapping
          // which shot it uses is "Choose"'s job, not this quick preview.
          if (match.alternates.isNotEmpty)
            Positioned(
              left: 6,
              bottom: 6,
              child: _AlternatesBadge(count: match.alternates.length),
            ),
        ],
      ),
    );
  }
}

/// "+N" pill marking a thumbnail that collapsed a burst of near-duplicate
/// shots into one suggestion.
class _AlternatesBadge extends StatelessWidget {
  const _AlternatesBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '+$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
