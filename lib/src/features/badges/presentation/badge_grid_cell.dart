import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/county_badge_medallion.dart';
import '../../../design/app_colors.dart';
import '../../map_home/domain/county_badge_state.dart';
import '../domain/badge_collection.dart';

/// One county in the collection: its badge inside a depth ring (a quarter
/// per depth level, from 12 o'clock clockwise). Pending counties get a
/// small marker so they don't read as locked. Tapping opens the county.
class BadgeGridCell extends StatelessWidget {
  const BadgeGridCell({
    super.key,
    required this.badge,
    this.onTap,
    this.coinBuilder,
  });

  final CountyBadge badge;
  final VoidCallback? onTap;

  /// Wraps the badge inside the ring (the sheet's spinning coin); the
  /// ring itself never moves.
  final Widget Function(double size)? coinBuilder;

  @override
  Widget build(BuildContext context) {
    final pending = badge.state == CountyBadgeState.pending;
    return Semantics(
      button: onTap != null,
      label:
          '${badge.county.name}: ${badge.state.statusLabel.toLowerCase()}, '
          '${badge.depth.label.toLowerCase()}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest.shortestSide;
            // Figma: an 80 px ring round a 74 px badge.
            final inset = size * 3 / 80;
            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.square(
                  dimension: size,
                  child: CustomPaint(
                    painter: _DepthRingPainter(
                      quarters: badge.depth.quarters,
                      stroke: math.max(2, size * 2.2 / 80),
                    ),
                  ),
                ),
                coinBuilder?.call(size - inset * 2) ??
                    CountyBadgeMedallion(
                      county: badge.county,
                      earned: badge.isEarned,
                      size: size - inset * 2,
                    ),
                if (pending)
                  const Positioned(bottom: 0, child: _PendingMarker()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DepthRingPainter extends CustomPainter {
  const _DepthRingPainter({required this.quarters, required this.stroke});

  final int quarters;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - stroke / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawOval(rect, paint..color = Colors.white);
    if (quarters <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi / 2 * quarters.clamp(0, 4),
      false,
      paint..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(_DepthRingPainter oldDelegate) =>
      oldDelegate.quarters != quarters || oldDelegate.stroke != stroke;
}

class _PendingMarker extends StatelessWidget {
  const _PendingMarker();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.pendingFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          'PENDING',
          style: AppTypeScale.meta.copyWith(
            color: Colors.white,
            fontSize: 8,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
