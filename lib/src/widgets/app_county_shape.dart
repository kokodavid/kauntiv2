import 'package:flutter/material.dart';

import '../counties/county_paths.dart';
import '../design/app_colors.dart';
import 'app_svg_path.dart';

class AppCountyShape extends StatelessWidget {
  const AppCountyShape({
    super.key,
    required this.county,
    this.fill = AppColors.green,
    this.stroke,
    this.strokeWidth = 0,
    this.dashed = false,
  });

  final CountyPath county;
  final Color fill;
  final Color? stroke;
  final double strokeWidth;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CountyShapePainter(
        county: county,
        fill: fill,
        stroke: stroke,
        strokeWidth: strokeWidth,
        dashed: dashed,
      ),
    );
  }
}

class AppCountryShape extends StatelessWidget {
  const AppCountryShape({
    super.key,
    this.fill = AppColors.green,
    this.stroke,
    this.strokeWidth = 0,
  });

  final Color fill;
  final Color? stroke;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CountryShapePainter(
        fill: fill,
        stroke: stroke,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _CountyShapePainter extends CustomPainter {
  const _CountyShapePainter({
    required this.county,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
    required this.dashed,
  });

  final CountyPath county;
  final Color fill;
  final Color? stroke;
  final double strokeWidth;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    _drawFittedPath(
      canvas,
      size,
      AppSvgPath.parse(county.pathData),
      fill: fill,
      stroke: stroke,
      strokeWidth: strokeWidth,
      dashed: dashed,
    );
  }

  @override
  bool shouldRepaint(covariant _CountyShapePainter oldDelegate) {
    return oldDelegate.county != county ||
        oldDelegate.fill != fill ||
        oldDelegate.stroke != stroke ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashed != dashed;
  }
}

class _CountryShapePainter extends CustomPainter {
  const _CountryShapePainter({
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });

  final Color fill;
  final Color? stroke;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (final county in CountyPaths.all) {
      path.addPath(AppSvgPath.parse(county.pathData), Offset.zero);
    }

    _drawPath(
      canvas,
      size,
      path,
      fill: fill,
      stroke: stroke,
      strokeWidth: strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _CountryShapePainter oldDelegate) {
    return oldDelegate.fill != fill ||
        oldDelegate.stroke != stroke ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

void _drawFittedPath(
  Canvas canvas,
  Size size,
  Path source, {
  required Color fill,
  Color? stroke,
  double strokeWidth = 0,
  bool dashed = false,
}) {
  final bounds = source.getBounds();
  if (bounds.isEmpty) {
    return;
  }

  final scale = [
    size.width / bounds.width,
    size.height / bounds.height,
  ].reduce((a, b) => a < b ? a : b);
  final dx = (size.width - bounds.width * scale) / 2;
  final dy = (size.height - bounds.height * scale) / 2;

  canvas.save();
  canvas.translate(dx, dy);
  canvas.scale(scale);
  canvas.translate(-bounds.left, -bounds.top);
  canvas.drawPath(source, Paint()..color = fill);

  if (stroke != null && strokeWidth > 0) {
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / scale;
    canvas.drawPath(dashed ? _dashPath(source) : source, strokePaint);
  }

  canvas.restore();
}

void _drawPath(
  Canvas canvas,
  Size size,
  Path source, {
  required Color fill,
  Color? stroke,
  double strokeWidth = 0,
  bool dashed = false,
}) {
  final scale = [
    size.width / CountyPaths.viewBoxWidth,
    size.height / CountyPaths.viewBoxHeight,
  ].reduce((a, b) => a < b ? a : b);
  final dx = (size.width - CountyPaths.viewBoxWidth * scale) / 2;
  final dy = (size.height - CountyPaths.viewBoxHeight * scale) / 2;

  canvas.save();
  canvas.translate(dx, dy);
  canvas.scale(scale);
  canvas.drawPath(source, Paint()..color = fill);

  if (stroke != null && strokeWidth > 0) {
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / scale;
    canvas.drawPath(dashed ? _dashPath(source) : source, strokePaint);
  }

  canvas.restore();
}

Path _dashPath(Path source, {double dash = 3, double gap = 2.4}) {
  final dashed = Path();
  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      dashed.addPath(
        metric.extractPath(distance, (distance + dash).clamp(0, metric.length)),
        Offset.zero,
      );
      distance += dash + gap;
    }
  }
  return dashed;
}
