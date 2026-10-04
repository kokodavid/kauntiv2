part of 'journey_camera_roll_sheet.dart';

class _MatchThumbnail extends StatelessWidget {
  const _MatchThumbnail({
    required this.match,
    required this.selected,
    required this.onTap,
    required this.onShowAlternates,
  });

  final CameraRollMatch match;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onShowAlternates;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _AssetThumbImage(asset: match.asset),
        ),
        if (!selected) ColoredBox(color: Colors.white.withValues(alpha: 0.55)),
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.accent : Colors.white,
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.cardBorder,
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ),
        if (onShowAlternates != null)
          Positioned(
            left: 6,
            bottom: 6,
            child: GestureDetector(
              onTap: onShowAlternates,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${match.alternates.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _ClusterAlternativesSheet extends StatelessWidget {
  const _ClusterAlternativesSheet({
    required this.cluster,
    required this.current,
  });

  final List<CameraRollMatch> cluster;
  final CameraRollMatch current;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.trackInactive,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const Text(
            'Choose this shot',
            style: AppTextStyles.confirmSheetTitle,
          ),
          const SizedBox(height: 4),
          const Text(
            'Taken moments apart - pick the one to use.',
            style: AppTypeScale.body,
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: cluster.length,
            itemBuilder: (context, index) {
              final item = cluster[index];
              final isCurrent = item.asset.id == current.asset.id;
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(item),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _AssetThumbImage(asset: item.asset),
                      ),
                      if (isCurrent)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _AssetThumbImage extends StatelessWidget {
  const _AssetThumbImage({required this.asset});

  final AssetEntity asset;

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: asset.thumbnailDataWithSize(const ThumbnailSize.square(200)),
    builder: (context, snapshot) {
      final bytes = snapshot.data;
      if (bytes == null) {
        return const ColoredBox(color: AppColors.lockedFill);
      }
      return Image.memory(bytes, fit: BoxFit.cover);
    },
  );
}
