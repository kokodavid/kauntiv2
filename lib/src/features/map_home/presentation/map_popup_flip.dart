import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Turns a card over on its vertical axis: [progress] 0 shows [front], 1
/// shows [back], and halfway it is edge-on, where the faces swap.
class MapPopupFlip extends StatelessWidget {
  const MapPopupFlip({
    super.key,
    required this.progress,
    required this.front,
    required this.back,
  });

  final Animation<double> progress;
  final Widget front;
  final Widget back;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final t = progress.value;
        final showBack = t > 0.5;
        // The back is drawn pre-turned so its text reads the right way round.
        final angle = showBack ? math.pi * (t - 1) : math.pi * t;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0014)
            ..rotateY(angle),
          child: showBack ? back : front,
        );
      },
    );
  }
}
