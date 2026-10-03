part of 'trip_share_card.dart';

/// The no-photo fallback: a cyan -> accent blue -> violet brand gradient
/// with the Trip's own route drawn faintly over it, so every photo-less
/// Trip still looks like its own Trip rather than a generic placeholder
/// (Claude-Design reference: "A cyan -> blue -> violet brand gradient
/// with the trip's route at 40% white, so each fallback is still
/// unique."). The cyan/violet hex values are placeholders pending real
/// brand colours; [AppColors.accent] anchors the middle of the gradient
/// since it's already the app's primary blue.
class _NoPhotoBackground extends StatelessWidget {
  const _NoPhotoBackground({required this.routePoints, required this.isShare});

  final List<Offset> routePoints;
  final bool isShare;

  static const _cyan = Color(0xFF3FD8F0);
  static const _violet = Color(0xFF6B4CF0);

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_cyan, AppColors.accent, _violet],
      ),
    ),
    child: routePoints.length < 2
        ? null
        : CustomPaint(
            painter: _RouteLinePainter(
              points: routePoints,
              // Thumbnail: a small squiggle tucked behind where the
              // stats sit. Share: "the route drawn large as the hero"
              // (Claude-Design reference) - most of the card.
              area: isShare
                  ? const Rect.fromLTWH(0.08, 0.06, 0.84, 0.56)
                  : const Rect.fromLTWH(0.55, 0.16, 0.38, 0.34),
            ),
          ),
  );
}
