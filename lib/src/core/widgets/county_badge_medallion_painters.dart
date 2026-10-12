part of 'county_badge_medallion.dart';

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
  const _DiscPainter({required this.earned, this.passedThrough = false});

  final bool earned;
  final bool passedThrough;

  /// The map's "passed" yellow as a lit rim and a three-stop face, the
  /// same way the blue and grey ones are built.
  static final _passedRim = [
    _shade(AppColors.legendPassed, 0.2),
    _shade(AppColors.legendPassed, -0.3),
  ];
  static final _passedFace = [
    _shade(AppColors.legendPassed, 0.15),
    AppColors.legendPassed,
    _shade(AppColors.legendPassed, -0.25),
  ];

  static Color _shade(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

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
          colors: earned
              ? _earnedRim
              : passedThrough
              ? _passedRim
              : _lockedRim,
        ).createShader(bounds),
    );
    canvas.drawCircle(
      center,
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: earned
              ? _earnedFace
              : passedThrough
              ? _passedFace
              : _lockedFace,
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
  bool shouldRepaint(_DiscPainter oldDelegate) =>
      oldDelegate.earned != earned ||
      oldDelegate.passedThrough != passedThrough;
}
