part of 'trip_share_sheet.dart';

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final JourneyMediaItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(
      item.capturedAt.toLocal(),
    ).format(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? const [
                      BoxShadow(color: Colors.white, spreadRadius: 2),
                      BoxShadow(color: AppColors.accent, spreadRadius: 4),
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(
                    image: appNetworkImage(
                      item.url,
                      cacheKey: item.id,
                      cacheWidth: 120,
                    ),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              if (frame == null)
                                const AppShimmer(
                                  child: AppSkeleton(width: 60, height: 60),
                                ),
                              AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                child: child,
                              ),
                            ],
                          );
                        },
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(color: AppColors.lockedFill),
                  ),
                ),
                if (selected)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: selected ? _Styles.thumbTimeSelected : _Styles.thumbTime,
          ),
        ],
      ),
    );
  }
}
