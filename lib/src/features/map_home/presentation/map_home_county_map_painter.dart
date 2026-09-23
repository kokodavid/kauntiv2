import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../../widgets/app_svg_path.dart';
import '../domain/map_home_models.dart';

/// Fit/centre transform from the county data's viewBox into a widget size.
class MapHomeMapTransform {
  const MapHomeMapTransform({required this.scale, required this.offset});

  factory MapHomeMapTransform.forSize(Size size) {
    final scale = math.min(
      size.width / CountyPaths.viewBoxWidth,
      size.height / CountyPaths.viewBoxHeight,
    );
    return MapHomeMapTransform(
      scale: scale,
      offset: Offset(
        (size.width - CountyPaths.viewBoxWidth * scale) / 2,
        (size.height - CountyPaths.viewBoxHeight * scale) / 2,
      ),
    );
  }

  final double scale;
  final Offset offset;

  Offset toMapPosition(Offset position) => Offset(
    (position.dx - offset.dx) / scale,
    (position.dy - offset.dy) / scale,
  );
}

/// Fill and stroke for a county's badge state, shared by the map and the
/// peek sheet so a county reads the same colour in both (v1 parity).
class MapHomeCountyStyle {
  const MapHomeCountyStyle({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  static MapHomeCountyStyle forState(
    MapHomeCountyBadgeState state, {
    bool isHome = false,
  }) {
    if (isHome && state != MapHomeCountyBadgeState.locked) {
      return const MapHomeCountyStyle(
        fill: AppColors.legendHome,
        stroke: Colors.white,
      );
    }
    return switch (state) {
      MapHomeCountyBadgeState.earned => const MapHomeCountyStyle(
        fill: AppColors.legendVisited,
        stroke: Colors.white,
      ),
      MapHomeCountyBadgeState.locked => const MapHomeCountyStyle(
        fill: Colors.white,
        stroke: AppColors.trackInactive,
      ),
      MapHomeCountyBadgeState.passedThrough => const MapHomeCountyStyle(
        fill: AppColors.legendPassed,
        stroke: Colors.white,
      ),
      // Visited blue at reduced opacity: earned, not yet confirmed online.
      MapHomeCountyBadgeState.pending => MapHomeCountyStyle(
        fill: AppColors.legendVisited.withValues(alpha: 0.55),
        stroke: Colors.white,
      ),
      MapHomeCountyBadgeState.justUnlocked => const MapHomeCountyStyle(
        fill: AppColors.mapJustUnlocked,
        stroke: Colors.white,
      ),
    };
  }
}

class MapHomeCountiesPainter extends CustomPainter {
  const MapHomeCountiesPainter({
    required this.badges,
    this.highlightedCountySlug,
    this.homeCountySlug,
  });

  final List<MapHomeCountyBadge> badges;
  final String? highlightedCountySlug;
  final String? homeCountySlug;

  static final Map<String, Path> _pathsBySlug = {
    for (final county in CountyPaths.all)
      county.slug: AppSvgPath.parse(county.pathData),
  };

  static Path pathFor(CountyPath county) => _pathsBySlug[county.slug]!;

  /// The county under [position], or the nearest one within a small
  /// on-screen halo so tiny counties (Nairobi, Mombasa) stay tappable.
  /// The halo shrinks in map space as [zoom] grows.
  static MapHomeCountyBadge? badgeAt(
    List<MapHomeCountyBadge> badges,
    Offset position,
    Size size, {
    double zoom = 1,
  }) {
    final transform = MapHomeMapTransform.forSize(size);
    final mapPosition = transform.toMapPosition(position);

    // Reversed to match the painter's stacking order at shared edges.
    for (final badge in badges.reversed) {
      if (pathFor(badge.county).contains(mapPosition)) return badge;
    }

    MapHomeCountyBadge? nearest;
    var nearestDistance = double.infinity;
    for (final badge in badges) {
      final distance =
          (pathFor(badge.county).getBounds().center - mapPosition).distance;
      if (distance < nearestDistance) {
        nearest = badge;
        nearestDistance = distance;
      }
    }
    if (nearestDistance <= 12 / (transform.scale * zoom)) return nearest;
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final transform = MapHomeMapTransform.forSize(size);
    final scale = transform.scale;
    Rect? justUnlockedBounds;
    var justUnlockedLabel = '';

    canvas.save();
    canvas.translate(transform.offset.dx, transform.offset.dy);
    canvas.scale(scale);

    for (final badge in badges) {
      final path = pathFor(badge.county);
      final style = MapHomeCountyStyle.forState(
        badge.state,
        isHome: badge.county.slug == homeCountySlug,
      );
      canvas.drawPath(path, Paint()..color = style.fill);
      canvas.drawPath(
        path,
        Paint()
          ..color = style.stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7 / scale,
      );
      if (badge.state == MapHomeCountyBadgeState.justUnlocked) {
        justUnlockedBounds = path.getBounds();
        final name = badge.county.name;
        justUnlockedLabel = name
            .substring(0, name.length.clamp(0, 3))
            .toUpperCase();
      }
    }

    final highlighted = _pathsBySlug[highlightedCountySlug];
    if (highlighted != null) {
      canvas.drawPath(
        highlighted,
        Paint()..color = AppColors.mapOverlayForeground.withValues(alpha: 0.16),
      );
      canvas.drawPath(
        highlighted,
        Paint()
          ..color = AppColors.mapHighlightStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / scale,
      );
    }

    canvas.restore();

    if (justUnlockedBounds != null) {
      _paintLabel(canvas, transform, justUnlockedBounds, justUnlockedLabel);
    }
  }

  void _paintLabel(
    Canvas canvas,
    MapHomeMapTransform transform,
    Rect bounds,
    String text,
  ) {
    final center = transform.offset + bounds.center * transform.scale;
    final painter = TextPainter(
      text: TextSpan(text: text, style: AppTextStyles.mapCountyLabel),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant MapHomeCountiesPainter oldDelegate) {
    return oldDelegate.badges != badges ||
        oldDelegate.highlightedCountySlug != highlightedCountySlug ||
        oldDelegate.homeCountySlug != homeCountySlug;
  }
}
