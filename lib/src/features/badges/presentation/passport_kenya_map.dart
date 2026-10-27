import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_svg_path.dart';
import '../domain/passport_level.dart';
import 'passport_palette.dart';

/// Kenya drawn from the 47 county shapes: stamped counties filled in their
/// level's colour, the rest pale, all with a thin outline. Decorative; the
/// card that holds it carries the spoken summary.
class PassportKenyaMap extends StatelessWidget {
  const PassportKenyaMap({super.key, required this.levels});

  /// The level of each county, by county code.
  final Map<int, PassportLevel> levels;

  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: CustomPaint(painter: _KenyaMapPainter(levels)));
}

class _KenyaMapPainter extends CustomPainter {
  const _KenyaMapPainter(this.levels);

  final Map<int, PassportLevel> levels;

  // Parsed once; every card reuses them.
  static final Map<int, Path> _paths = {
    for (final county in CountyPaths.all)
      county.code: AppSvgPath.parse(county.pathData),
  };
  static final Rect _bounds = _paths.values
      .map((path) => path.getBounds())
      .reduce((a, b) => a.expandToInclude(b));

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / _bounds.width,
      size.height / _bounds.height,
    );
    canvas.save();
    canvas.translate(
      (size.width - _bounds.width * scale) / 2,
      (size.height - _bounds.height * scale) / 2,
    );
    canvas.scale(scale);
    canvas.translate(-_bounds.left, -_bounds.top);
    final pale = Paint()..color = Colors.white.withValues(alpha: 0.55);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9 / scale
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.accent.withValues(alpha: 0.3);
    for (final MapEntry(key: code, value: path) in _paths.entries) {
      final level = levels[code] ?? PassportLevel.none;
      canvas.drawPath(
        path,
        level == PassportLevel.none ? pale : (Paint()..color = level.ring),
      );
      canvas.drawPath(path, line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KenyaMapPainter oldDelegate) =>
      !identical(oldDelegate.levels, levels);
}
