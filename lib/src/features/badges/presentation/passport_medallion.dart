import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/county_badge_medallion.dart';
import '../../../counties/county_paths.dart';
import '../domain/passport_level.dart';
import 'passport_palette.dart';

/// A county medallion inside its level ring: solid in the level colour,
/// three-segment grey for Passed Through, none before the first stamp. The art
/// itself never changes; it is blue from Explored up and grey below.
class PassportMedallion extends StatelessWidget {
  const PassportMedallion({
    super.key,
    required this.county,
    required this.level,
    required this.size,
    this.ringWidth = 2.5,
    this.gap = 2,
    this.matColor,
  });

  final CountyPath county;
  final PassportLevel level;

  /// The medallion's own diameter; the ring and gap sit outside it.
  final double size;
  final double ringWidth;
  final double gap;

  /// A mat between medallion and ring (the hero uses white).
  final Color? matColor;

  @override
  Widget build(BuildContext context) {
    final inner = size + gap * 2;
    final outer = inner + ringWidth * 2;
    return SizedBox.square(
      dimension: outer,
      child: CustomPaint(
        painter: _RingPainter(
          color: level.ring,
          width: ringWidth,
          dashed: level == PassportLevel.passedThrough,
          mat: matColor,
        ),
        child: Center(
          child: CountyBadgeMedallion(
            county: county,
            earned: level.index >= PassportLevel.explored.index,
            size: size,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.color,
    required this.width,
    required this.dashed,
    this.mat,
  });

  final Color color;
  final double width;
  final bool dashed;
  final Color? mat;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - width / 2;
    if (mat != null) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.fill
          ..color = mat!,
      );
    }
    if (color == Colors.transparent) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;
    if (!dashed) {
      canvas.drawCircle(center, radius, paint);
      return;
    }
    // Three unbroken arcs with small gaps between them.
    const segments = 3;
    const gap = 0.42; // radians (about 24 degrees)
    const sweep = 2 * math.pi / segments - gap;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final capped = paint..strokeCap = StrokeCap.round;
    for (var i = 0; i < segments; i++) {
      final start = -math.pi / 2 + gap / 2 + i * (2 * math.pi / segments);
      canvas.drawArc(rect, start, sweep, false, capped);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color ||
      old.width != width ||
      old.dashed != dashed ||
      old.mat != mat;
}
