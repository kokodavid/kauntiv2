import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import 'passport_cover_palette.dart';
import 'passport_text.dart';

/// Three dashed gold stamp previews for a traveller with no stamps yet:
/// Passed, Explored, Bronze +. They show what the passport will collect.
class PassportCoverStamps extends StatelessWidget {
  const PassportCoverStamps({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Preview(
          title: 'PASSED',
          hint: 'Enter a county',
          tilt: -6,
          rounded: true,
        ),
        SizedBox(width: 8),
        _Preview(title: 'EXPLORED', hint: 'A 2 h visit'),
        SizedBox(width: 8),
        _Preview(title: 'BRONZE +', hint: 'Discover places'),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.title,
    required this.hint,
    this.tilt = 0,
    this.rounded = false,
  });

  final String title;
  final String hint;
  final double tilt;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt * math.pi / 180,
      child: CustomPaint(
        painter: _DashedPainter(rounded: rounded),
        child: SizedBox(
          width: 92,
          height: rounded ? 70 : 92,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    style: passportText(
                      10,
                      weight: FontWeight.w700,
                      color: PassportCoverPalette.gold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: passportText(
                      10.5,
                      color: PassportCoverPalette.softText,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  const _DashedPainter({required this.rounded});

  final bool rounded;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1);
    final path = Path()
      ..addRRect(
        rounded
            ? RRect.fromRectAndRadius(rect, const Radius.circular(12))
            : RRect.fromRectAndRadius(rect, Radius.circular(size.width / 2)),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = PassportCoverPalette.gold.withValues(alpha: 0.8);
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 3), paint);
        distance += 6;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) => old.rounded != rounded;
}
