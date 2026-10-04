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

  /// Newspaper ("In the news", County Detail) - lucide `newspaper`, traced
  /// from its own SVG: `M4 22h16a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2H8a2 2 0 0
  /// 0-2 2v16a2 2 0 0 1-2 2Zm0 0a2 2 0 0 1-2-2v-9c0-1.1.9-2 2-2h2`, `M18
  /// 14h-8`, `M15 18h-5`, `M10 6h8v4h-8V6Z`. Flutter's own
  /// `Icons.article_outlined` doesn't carry the folded bottom-left corner
  /// that makes this read as a newspaper rather than a plain document.
  static Path newspaper() => Path()
    ..moveTo(4, 22)
    ..relativeLineTo(16, 0)
    ..relativeArcToPoint(const Offset(2, -2), radius: const Radius.circular(2))
    ..lineTo(22, 4)
    ..relativeArcToPoint(const Offset(-2, -2), radius: const Radius.circular(2))
    ..lineTo(8, 2)
    ..relativeArcToPoint(const Offset(-2, 2), radius: const Radius.circular(2))
    ..relativeLineTo(0, 16)
    ..relativeArcToPoint(
      const Offset(-2, 2),
      radius: const Radius.circular(2),
      clockwise: true,
    )
    ..close()
    ..moveTo(4, 22)
    ..relativeArcToPoint(
      const Offset(-2, -2),
      radius: const Radius.circular(2),
      clockwise: true,
    )
    ..relativeLineTo(0, -9)
    ..relativeCubicTo(0, -1.1, 0.9, -2, 2, -2)
    ..relativeLineTo(2, 0)
    ..moveTo(18, 14)
    ..relativeLineTo(-8, 0)
    ..moveTo(15, 18)
    ..relativeLineTo(-5, 0)
    ..moveTo(10, 6)
    ..relativeLineTo(8, 0)
    ..relativeLineTo(0, 4)
    ..relativeLineTo(-8, 0)
    ..lineTo(10, 6)
    ..close();
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
