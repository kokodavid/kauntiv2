part of 'trip_share_sheet.dart';

/// Stand-in for [_PhotoStrip] while the Trip's media is still loading -
/// same 60x60 thumb size, gap and time-label row, so the strip doesn't
/// jump when the real thumbnails drop in.
class _PhotoStripSkeleton extends StatelessWidget {
  const _PhotoStripSkeleton();

  static const _count = 4;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 88,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(top: 6),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < _count; i++) ...[
          const Column(
            children: [
              AppSkeleton(width: 60, height: 60, radius: 12),
              SizedBox(height: 4),
              AppSkeleton(width: 34, height: 10, radius: 4),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );
}
