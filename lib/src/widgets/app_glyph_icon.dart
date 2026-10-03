import 'package:flutter/material.dart';

/// Stroke-style icon glyphs traced directly from the Claude-Design
/// references (lucide-style paths, 24x24 viewBox, round caps/joins) for
/// the handful of cases where Flutter's own Material icons don't match
/// the design closely enough - e.g. [Icons.download_rounded]'s filled
/// tray vs. the reference's open stroke one, or [Icons.ios_share_rounded]'s
/// different proportions vs. the reference's own upload glyph. Each
/// builder returns a fresh [Path] in 24x24 units; [AppGlyphIcon] scales
/// and strokes it to any requested size.
abstract final class AppGlyphPaths {
  /// Arrow down into an open-top tray ("Save to Photos") - Claude-Design
  /// "Share Sheet 3a" reference, traced from its own SVG:
  /// `M12 15V3M7 10l5 5 5-5M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4`.
  static Path download() => Path()
    ..moveTo(12, 15)
    ..lineTo(12, 3)
    ..moveTo(7, 10)
    ..lineTo(12, 15)
    ..lineTo(17, 10)
    ..moveTo(21, 15)
    ..lineTo(21, 19)
    ..arcToPoint(const Offset(19, 21), radius: const Radius.circular(2))
    ..lineTo(5, 21)
    ..arcToPoint(const Offset(3, 19), radius: const Radius.circular(2))
    ..lineTo(3, 15);

  /// Arrow up out of an open-top tray ("Share") - same reference, its
  /// own Share button SVG: `M12 3v12M7 8l5-5 5 5M20 14v5a2 2 0 0 1-2
  /// 2H6a2 2 0 0 1-2-2v-5`. The mirror of [download] top-to-bottom.
  static Path share() => Path()
    ..moveTo(12, 3)
    ..lineTo(12, 15)
    ..moveTo(7, 8)
    ..lineTo(12, 3)
    ..lineTo(17, 8)
    ..moveTo(20, 14)
    ..lineTo(20, 19)
    ..arcToPoint(const Offset(18, 21), radius: const Radius.circular(2))
    ..lineTo(6, 21)
    ..arcToPoint(const Offset(4, 19), radius: const Radius.circular(2))
    ..lineTo(4, 14);
}

/// Strokes an [AppGlyphPaths] path at any size, matching the reference's
/// 2.2-at-24 line weight (scaled proportionally with the icon itself) and
/// its round caps/joins.
class AppGlyphIcon extends StatelessWidget {
  const AppGlyphIcon({
    super.key,
    required this.path,
    this.size = 20,
    required this.color,
    this.strokeWidth = 2.2,
  });

  /// A builder, not a [Path] directly - [Path] is mutable and building a
  /// fresh one per paint avoids any risk of two [AppGlyphIcon]s (or
  /// rebuilds) sharing and mutating the same instance.
  final Path Function() path;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _AppGlyphIconPainter(
      path: path(),
      color: color,
      strokeWidth: strokeWidth,
    ),
  );
}

class _AppGlyphIconPainter extends CustomPainter {
  const _AppGlyphIconPainter({
    required this.path,
    required this.color,
    required this.strokeWidth,
  });

  final Path path;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AppGlyphIconPainter oldDelegate) =>
      oldDelegate.path != path ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
