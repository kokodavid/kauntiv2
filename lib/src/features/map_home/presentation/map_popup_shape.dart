import 'package:flutter/material.dart';

/// A rounded card with a small tail under it, pointing at [tailX] from the
/// card's left edge. The tail is part of the card's own height.
class MapPopupShape extends ShapeBorder {
  const MapPopupShape({
    required this.tailX,
    this.radius = 26,
    this.tail = tailHeight,
  });

  final double tailX;
  final double radius;

  /// Height of the tail; 0 draws a plain rounded card.
  final double tail;

  static const tailHeight = 14.0;
  static const _tailWidth = 22.0;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final body = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      rect.height - tail,
    );
    final cx = rect.left + tailX;
    final card = Path()
      ..addRRect(RRect.fromRectAndRadius(body, Radius.circular(radius)));
    if (tail == 0) return card;
    return card
      ..moveTo(cx - _tailWidth / 2, body.bottom - 1)
      ..lineTo(cx, rect.bottom)
      ..lineTo(cx + _tailWidth / 2, body.bottom - 1)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) =>
      MapPopupShape(tailX: tailX, radius: radius, tail: tail);
}
