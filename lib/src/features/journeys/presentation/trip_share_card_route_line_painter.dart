part of 'trip_share_card.dart';

class _RouteLinePainter extends CustomPainter {
  _RouteLinePainter({required this.points, required this.area});

  /// Unit-square normalized (see [TripShareCard.normalizeRoute]).
  final List<Offset> points;

  /// The unit-square sub-rect to draw the route within.
  final Rect area;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      area.left * size.width,
      area.top * size.height,
      area.width * size.width,
      area.height * size.height,
    );
    Offset at(int i) => Offset(
      rect.left + points[i].dx * rect.width,
      rect.top + points[i].dy * rect.height,
    );
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      final p = at(i);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // A solid dot at the end, like the finish of a route - the
    // reference's own route-line sketches end this way.
    canvas.drawCircle(
      at(points.length - 1),
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _RouteLinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.area != area;
}
