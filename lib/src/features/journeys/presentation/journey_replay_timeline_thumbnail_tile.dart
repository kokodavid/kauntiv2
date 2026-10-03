part of 'journey_replay_timeline.dart';

class _ThumbnailTile extends StatelessWidget {
  const _ThumbnailTile({required this.match});

  final CameraRollMatch match;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
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
    );
  }
}
