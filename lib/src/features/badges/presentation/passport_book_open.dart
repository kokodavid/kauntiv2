import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'passport_cover_palette.dart';
import 'passport_text.dart';

/// Opens the cover like a book. The cover turns about its left edge (the
/// spine) while the page beneath settles from 94% to full size; a shadow
/// along the spine fades out. With reduced motion the cover just fades.
class PassportBookOpen extends StatelessWidget {
  const PassportBookOpen({
    super.key,
    required this.animation,
    required this.page,
    required this.cover,
    required this.reduceMotion,
  });

  /// 0 (cover shut) to 1 (open).
  final Animation<double> animation;
  final Widget page;
  final Widget cover;
  final bool reduceMotion;

  static const _curve = Cubic(0.6, 0.05, 0.25, 1);
  static const _openAngle = 112 * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = reduceMotion
            ? animation.value
            : _curve.transform(animation.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: reduceMotion ? 1 : 0.94 + 0.06 * t,
              child: page,
            ),
            if (!reduceMotion)
              IgnorePointer(
                child: Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0x47000000), Color(0x00000000)],
                        stops: [0, 0.6],
                      ),
                    ),
                  ),
                ),
              ),
            if (animation.value < 1)
              IgnorePointer(ignoring: animation.value > 0, child: _cover(t)),
          ],
        );
      },
    );
  }

  Widget _cover(double t) {
    if (reduceMotion) {
      return Opacity(opacity: (1 - t).clamp(0.0, 1.0), child: cover);
    }
    // Positive turns the free edge towards the viewer (Flutter's
    // perspective shrinks what moves to positive z), like a cover lifting.
    final angle = _openAngle * t;
    // Past a quarter turn the viewer sees the cover's inside.
    final showsBack = angle > math.pi / 2;
    return Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0007)
        ..rotateY(angle),
      child: showsBack
          ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: const _CoverInside(),
            )
          : cover,
    );
  }
}

class _CoverInside extends StatelessWidget {
  const _CoverInside();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PassportCoverPalette.navy,
      child: Center(
        child: Text(
          'KAUNTI47',
          style: passportText(
            12,
            weight: FontWeight.w600,
            color: PassportCoverPalette.gold,
            letterSpacing: 2.4,
          ),
        ),
      ),
    );
  }
}
