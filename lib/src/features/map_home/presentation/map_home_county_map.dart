import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_svg_path.dart';
import '../domain/map_home_models.dart';
import 'county_peek_sheet.dart';

class MapHomeCountyMap extends StatelessWidget {
  const MapHomeCountyMap({
    super.key,
    required this.badges,
    required this.homeCountySlug,
  });

  final List<MapHomeCountyBadge> badges;
  final String? homeCountySlug;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final badge = _MapHomeCountiesPainter.badgeAt(
          badges,
          details.localPosition,
          box.size,
        );
        if (badge != null) _showCountyPeek(context, badge);
      },
      child: CustomPaint(
        painter: _MapHomeCountiesPainter(
          badges: badges,
          homeCountySlug: homeCountySlug,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Future<void> _showCountyPeek(
    BuildContext context,
    MapHomeCountyBadge badge,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.foreground.withValues(alpha: 0.28),
      builder: (context) => CountyPeekSheet(
        badge: badge,
        isHome: badge.county.slug == homeCountySlug,
      ),
    );
  }
}

class _MapHomeCountiesPainter extends CustomPainter {
  _MapHomeCountiesPainter({
    required this.badges,
    required this.homeCountySlug,
  });

  final List<MapHomeCountyBadge> badges;
  final String? homeCountySlug;

  static final _paths = {
    for (final county in CountyPaths.all)
      county.slug: AppSvgPath.parse(county.pathData),
  };

  static MapHomeCountyBadge? badgeAt(
    List<MapHomeCountyBadge> badges,
    Offset position,
    Size size,
  ) {
    final transform = _CountyMapTransform.forSize(size);
    final mapPosition = transform.toMapPosition(position);
    for (final badge in badges.reversed) {
      if (_paths[badge.county.slug]!.contains(mapPosition)) return badge;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final transform = _CountyMapTransform.forSize(size);
    canvas.save();
    canvas.translate(transform.offset.dx, transform.offset.dy);
    canvas.scale(transform.scale);

    for (final badge in badges) {
      final isHome = badge.county.slug == homeCountySlug;
      final path = _paths[badge.county.slug]!;
      canvas.drawPath(
        path,
        Paint()..color = _fillFor(badge.state, isHome: isHome),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = _strokeFor(badge.state, isHome: isHome),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MapHomeCountiesPainter oldDelegate) {
    return oldDelegate.badges != badges ||
        oldDelegate.homeCountySlug != homeCountySlug;
  }

  Color _fillFor(MapHomeCountyBadgeState state, {required bool isHome}) {
    if (isHome) return AppColors.legendHome;
    return switch (state) {
      MapHomeCountyBadgeState.earned => AppColors.legendVisited,
      MapHomeCountyBadgeState.locked => AppColors.lockedFill,
      MapHomeCountyBadgeState.passedThrough => AppColors.legendPassed,
      MapHomeCountyBadgeState.pending => AppColors.pendingFill,
      MapHomeCountyBadgeState.justUnlocked => AppColors.justUnlockedFill,
    };
  }

  Color _strokeFor(MapHomeCountyBadgeState state, {required bool isHome}) {
    if (isHome || state != MapHomeCountyBadgeState.locked) {
      return Colors.white;
    }
    return AppColors.lockedStroke;
  }
}

class _CountyMapTransform {
  const _CountyMapTransform({required this.scale, required this.offset});

  final double scale;
  final Offset offset;

  Offset toMapPosition(Offset screenPosition) {
    return Offset(
      (screenPosition.dx - offset.dx) / scale,
      (screenPosition.dy - offset.dy) / scale,
    );
  }

  static _CountyMapTransform forSize(Size size) {
    final scale = math.min(
      size.width / CountyPaths.viewBoxWidth,
      size.height / CountyPaths.viewBoxHeight,
    );
    final drawnSize = Size(
      CountyPaths.viewBoxWidth * scale,
      CountyPaths.viewBoxHeight * scale,
    );
    final offset = Offset(
      (size.width - drawnSize.width) / 2,
      math.max(0, (size.height - drawnSize.height) * 0.08),
    );
    return _CountyMapTransform(scale: scale, offset: offset);
  }
}
