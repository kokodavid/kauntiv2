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
                  child: Image.network(
                    item.url,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    cacheWidth: 120,
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
