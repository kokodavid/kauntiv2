import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/trip_plan_summary.dart';
import 'plan_day_colors.dart';

/// The plan card's route shape: each day's stops joined in that day's
/// colour, with a dark ring at the start (design 1b). Grey for a past plan.
class PlanRouteThumbnail extends StatelessWidget {
  const PlanRouteThumbnail({super.key, required this.plan, this.size = 72});

  final TripPlanSummary plan;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.lockedFill,
      borderRadius: BorderRadius.circular(10),
    ),
    child: CustomPaint(
      painter: _RoutePainter(
        days: [
          for (final day in plan.days)
            if (day.points.isNotEmpty) day,
        ],
        muted: plan.isPast,
      ),
    ),
  );
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.days, required this.muted});

  final List<PlanDaySummary> days;
  final bool muted;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [for (final day in days) ...day.points];
    if (points.isEmpty) return;
    var minLat = points.first.$1, maxLat = points.first.$1;
    var minLng = points.first.$2, maxLng = points.first.$2;
    for (final (lat, lng) in points) {
      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLng = math.min(minLng, lng);
      maxLng = math.max(maxLng, lng);
    }
    const pad = 14.0;
    final span = math.max(maxLat - minLat, maxLng - minLng);
    final scale = span == 0 ? 0.0 : (size.shortestSide - pad * 2) / span;
    Offset toOffset((double, double) p) => Offset(
      size.width / 2 + (p.$2 - (minLng + maxLng) / 2) * scale,
      size.height / 2 - (p.$1 - (minLat + maxLat) / 2) * scale,
    );

    Offset? previous;
    for (final day in days) {
      final paint = Paint()
        ..color = muted ? AppColors.disabledText : PlanDayColors.of(day.number)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path();
      final first = toOffset(day.points.first);
      // Each day picks up where the last one ended.
      path.moveTo((previous ?? first).dx, (previous ?? first).dy);
      for (final point in day.points) {
        final o = toOffset(point);
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, paint);
      previous = toOffset(day.points.last);
    }

    final start = toOffset(points.first);
    canvas
      ..drawCircle(start, 4.5, Paint()..color = Colors.white)
      ..drawCircle(
        start,
        4.5,
        Paint()
          ..color = AppColors.foreground
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.days != days || old.muted != muted;
}
