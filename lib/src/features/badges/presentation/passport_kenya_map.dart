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
  const PassportKenyaMap({
    super.key,
    required this.levels,
    this.onPhoto = false,
  });

  /// The level of each county, by county code.
  final Map<int, PassportLevel> levels;

  /// Drawn over a photo (the Passport share card): unstamped counties are
  /// a faint white, outlines white, and Passed Through a lighter grey so
  /// it still reads on a dark background.
  final bool onPhoto;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(painter: _KenyaMapPainter(levels, onPhoto: onPhoto)),
  );
}

class _KenyaMapPainter extends CustomPainter {
  const _KenyaMapPainter(this.levels, {required this.onPhoto});

  final Map<int, PassportLevel> levels;
  final bool onPhoto;

  static const _passedOnPhoto = Color(0xFFD4D4D8);

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
    final pale = Paint()
      ..color = Colors.white.withValues(alpha: onPhoto ? 0.18 : 0.55);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9 / scale
      ..strokeJoin = StrokeJoin.round
      ..color = onPhoto
          ? Colors.white.withValues(alpha: 0.75)
          : AppColors.accent.withValues(alpha: 0.3);
    for (final MapEntry(key: code, value: path) in _paths.entries) {
      final level = levels[code] ?? PassportLevel.none;
      final fill = switch (level) {
        PassportLevel.none => null,
        PassportLevel.passedThrough when onPhoto => _passedOnPhoto,
        _ => level.ring,
      };
      canvas.drawPath(path, fill == null ? pale : (Paint()..color = fill));
      canvas.drawPath(path, line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KenyaMapPainter oldDelegate) =>
      !identical(oldDelegate.levels, levels) || oldDelegate.onPhoto != onPhoto;
}
