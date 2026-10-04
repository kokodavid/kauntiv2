import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/public_trip_owner_view.dart';

/// The sanitized route as the public will see it, drawn to fit its box.
/// The start and end dots mark where the route now begins and ends, after
/// the hidden parts are cut off.
class PublicTripRoutePreview extends StatelessWidget {
  const PublicTripRoutePreview({
    super.key,
    required this.lines,
    required this.moments,
    this.height = 200,
  });

  final List<List<PublicTripPoint>> lines;
  final List<PublicTripMoment> moments;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Preview of the public route',
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.noteBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: _RoutePainter(lines: lines, moments: moments),
          ),
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.lines, required this.moments});

  final List<List<PublicTripPoint>> lines;
  final List<PublicTripMoment> moments;

  static const _padding = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final all = [for (final line in lines) ...line];
    if (all.length < 2) return;
    var minLat = all.first.latitude;
    var maxLat = minLat;
    var minLon = all.first.longitude;
    var maxLon = minLon;
    for (final point in all) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLon = math.min(minLon, point.longitude);
      maxLon = math.max(maxLon, point.longitude);
    }
    // Longitude degrees shrink away from the equator; correct for it so
    // the shape is not stretched.
    final lonScale = math.cos((minLat + maxLat) / 2 * math.pi / 180);
    final spanX = math.max((maxLon - minLon) * lonScale, 1e-6);
    final spanY = math.max(maxLat - minLat, 1e-6);
    final scale = math.min(
      (size.width - _padding * 2) / spanX,
      (size.height - _padding * 2) / spanY,
    );
    final offsetX = (size.width - spanX * scale) / 2;
    final offsetY = (size.height - spanY * scale) / 2;

    Offset project(PublicTripPoint p) => Offset(
      offsetX + (p.longitude - minLon) * lonScale * scale,
      size.height - offsetY - (p.latitude - minLat) * scale,
    );

    final stroke = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final line in lines) {
      if (line.length < 2) continue;
      final path = Path()
        ..moveTo(project(line.first).dx, project(line.first).dy);
      for (final point in line.skip(1)) {
        final o = project(point);
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, stroke);
    }

    final momentPaint = Paint()..color = AppColors.pendingFill;
    for (final moment in moments) {
      canvas.drawCircle(
        project(PublicTripPoint(moment.latitude, moment.longitude)),
        4.5,
        momentPaint,
      );
    }

    final ring = Paint()..color = Colors.white;
    void dot(PublicTripPoint p, Color color) {
      canvas
        ..drawCircle(project(p), 8, ring)
        ..drawCircle(project(p), 5.5, Paint()..color = color);
    }

    dot(lines.first.first, AppColors.legendHome);
    dot(lines.last.last, AppColors.danger);
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.lines != lines || old.moments != moments;
}
