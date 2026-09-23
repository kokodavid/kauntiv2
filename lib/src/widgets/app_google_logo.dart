import 'package:flutter/material.dart';

/// The official multi-color Google "G" mark used on the "Continue with
/// Google" button. Google's brand guidelines require the actual logo mark
/// rather than a generic letter glyph, so this is painted from Google's own
/// published icon geometry (48x48 viewBox) instead of a Material icon.
class AppGoogleLogo extends StatelessWidget {
  const AppGoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48;
    canvas.save();
    canvas.scale(scale);

    canvas.drawPath(_bluePath(), Paint()..color = _blue);
    canvas.drawPath(_greenPath(), Paint()..color = _green);
    canvas.drawPath(_yellowPath(), Paint()..color = _yellow);
    canvas.drawPath(_redPath(), Paint()..color = _red);

    canvas.restore();
  }

  Path _bluePath() => Path()
    ..moveTo(45.12, 24.5)
    ..cubicTo(45.12, 22.94, 44.98, 21.44, 44.72, 20.0)
    ..lineTo(24.0, 20.0)
    ..lineTo(24.0, 28.51)
    ..lineTo(35.84, 28.51)
    ..cubicTo(35.33, 31.26, 33.78, 33.59, 31.45, 35.15)
    ..lineTo(31.45, 40.67)
    ..lineTo(38.56, 40.67)
    ..cubicTo(42.72, 36.84, 45.12, 31.2, 45.12, 24.5)
    ..close();

  Path _greenPath() => Path()
    ..moveTo(24.0, 46.0)
    ..cubicTo(29.94, 46.0, 34.92, 44.03, 38.56, 40.67)
    ..lineTo(31.45, 35.15)
    ..cubicTo(29.48, 36.47, 26.96, 37.25, 24.0, 37.25)
    ..cubicTo(18.27, 37.25, 13.42, 33.38, 11.69, 28.18)
    ..lineTo(4.34, 28.18)
    ..lineTo(4.34, 33.88)
    ..cubicTo(7.96, 41.07, 15.4, 46.0, 24.0, 46.0)
    ..close();

  Path _yellowPath() => Path()
    ..moveTo(11.69, 28.18)
    ..cubicTo(11.25, 26.86, 11.0, 25.45, 11.0, 24.0)
    ..cubicTo(11.0, 22.55, 11.25, 21.14, 11.69, 19.82)
    ..lineTo(11.69, 14.12)
    ..lineTo(4.34, 14.12)
    ..arcToPoint(
      const Offset(2.0, 24.0),
      radius: const Radius.circular(21.93),
      clockwise: false,
    )
    ..cubicTo(2.0, 27.55, 2.85, 30.91, 4.34, 33.88)
    ..lineTo(11.69, 28.18)
    ..close();

  Path _redPath() => Path()
    ..moveTo(24.0, 10.75)
    ..cubicTo(27.23, 10.75, 30.13, 11.86, 32.41, 14.04)
    ..lineTo(38.72, 7.73)
    ..cubicTo(34.91, 4.18, 29.93, 2.0, 24.0, 2.0)
    ..cubicTo(15.4, 2.0, 7.96, 6.93, 4.34, 14.12)
    ..lineTo(11.69, 19.82)
    ..cubicTo(13.42, 14.62, 18.27, 10.75, 24.0, 10.75)
    ..close();

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
