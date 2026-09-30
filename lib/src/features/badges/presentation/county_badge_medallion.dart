import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../counties/county_paths.dart';
import '../../../widgets/app_county_shape.dart';
import '../../../widgets/app_svg_path.dart';

/// A county badge (Figma "Badge", no stars): a glossy disc with the county
/// name across the top and its silhouette in white. Blue once earned,
/// grey otherwise. Drawn at any [size]; the design is 74 px. With [back]
/// it's the coin's reverse: the same disc with the Kaunti47 mark.
class CountyBadgeMedallion extends StatelessWidget {
  const CountyBadgeMedallion({
    super.key,
    required this.county,
    required this.earned,
    this.size = 74,
    this.back = false,
  });

  final CountyPath county;
  final bool earned;
  final double size;
  final bool back;

  @override
  Widget build(BuildContext context) {
    final unit = size / 74;
    if (back) return _back(unit);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DiscPainter(earned: earned)),
          ),
          Positioned(
            left: 6 * unit,
            right: 6 * unit,
            top: 12.3 * unit,
            child: Text(
              county.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypeScale.family,
                fontWeight: FontWeight.w600,
                fontSize: 7.7 * unit,
                height: 1.2,
                letterSpacing: 0.2 * unit,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: const Color(0x1F000000),
                    offset: Offset(0, 0.77 * unit),
                    blurRadius: 4.6 * unit,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 17 * unit,
            right: 17 * unit,
            top: 25 * unit,
            bottom: 17 * unit,
            child: AppCountyShape(county: county, fill: Colors.white),
          ),
        ],
      ),
    );
  }
}

extension on CountyBadgeMedallion {
  /// The reverse: Kenya's map with this county picked out in white, and
  /// the Kaunti47 mark under it.
  Widget _back(double unit) => SizedBox.square(
    dimension: size,
    child: Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _DiscPainter(earned: earned)),
        ),
        Positioned(
          left: 18 * unit,
          right: 18 * unit,
          top: 12 * unit,
          bottom: 20 * unit,
          child: CustomPaint(painter: _KenyaPainter(county.code)),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10 * unit,
          child: Text(
            'KAUNTI47',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypeScale.family,
              fontWeight: FontWeight.w600,
              fontSize: 6 * unit,
              letterSpacing: 1 * unit,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

/// All 47 counties, faint, with [highlight] solid: the country outline
/// on the coin's back. Paths are parsed once and reused every frame.
class _KenyaPainter extends CustomPainter {
  const _KenyaPainter(this.highlight);

  final int highlight;

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
    final faint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (final MapEntry(key: code, value: path) in _paths.entries) {
      if (code != highlight) canvas.drawPath(path, faint);
    }
    final picked = _paths[highlight];
    if (picked != null) {
      canvas.drawPath(picked, Paint()..color = Colors.white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KenyaPainter oldDelegate) =>
      oldDelegate.highlight != highlight;
}

/// The disc: a rim (lit from above) round an inner face with a soft light
/// band down its left side. Colours sampled from the Figma badge.
class _DiscPainter extends CustomPainter {
  const _DiscPainter({required this.earned});

  final bool earned;

  static const _earnedRim = [Color(0xFF0BD9FF), Color(0xFF004BD8)];
  static const _earnedFace = [
    Color(0xFF00E1FB),
    Color(0xFF2AAFF3),
    Color(0xFF005FE9),
  ];
  static const _lockedRim = [Color(0xFFB4B4BB), Color(0xFF4B4B53)];
  static const _lockedFace = [
    Color(0xFFA1A1AA),
    Color(0xFF7C7C85),
    Color(0xFF52525B),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    final face = radius * 0.84;
    final faceRect = Rect.fromCircle(center: center, radius: face);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: earned ? _earnedRim : _lockedRim,
        ).createShader(bounds),
    );
    canvas.drawCircle(
      center,
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: earned ? _earnedFace : _lockedFace,
        ).createShader(faceRect),
    );
    // Soft light down the left of the face.
    canvas.save();
    canvas.clipPath(Path()..addOval(faceRect));
    canvas.drawRect(
      Rect.fromLTRB(
        faceRect.left,
        faceRect.top,
        center.dx - face * 0.15,
        faceRect.bottom,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    // Top glow.
    canvas.drawCircle(
      center.translate(0, -face * 0.35),
      face * 0.75,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.28),
                Colors.white.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: center.translate(0, -face * 0.35),
                radius: face * 0.75,
              ),
            ),
    );
    canvas.restore();
    // Thin edge between rim and face.
    canvas.drawCircle(
      center,
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, radius * 0.025)
        ..color = Colors.black.withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(_DiscPainter oldDelegate) => oldDelegate.earned != earned;
}
