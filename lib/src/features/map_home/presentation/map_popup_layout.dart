import 'dart:math' as math;
import 'dart:ui';

/// Where the map popup sits and where the camera must put the pin for it.
///
/// The popup is a card with a small tail whose tip points at the place's
/// spot on the map. The tip lands in the horizontal middle of the screen,
/// low enough that the whole card fits under the header and above the nav.
class MapPopupLayout {
  const MapPopupLayout({
    required this.screen,
    required this.topInset,
    required this.bottomReserve,
  });

  final Size screen;

  /// Height taken from the top by Home's header.
  final double topInset;

  /// Height kept clear at the bottom (the nav bar and its margin).
  final double bottomReserve;

  static const tail = 14.0;
  static const _gap = 6.0;
  static const margin = 12.0;
  static const _maxBody = 268.0;
  static const _minBody = 200.0;
  static const _maxWidth = 264.0;

  double get width => math.min(_maxWidth, screen.width - margin * 2);

  double get _top => topInset + 8;

  /// Screen y where the pin should end up.
  double get anchorY =>
      math.min(_top + _maxBody + tail + _gap, screen.height - bottomReserve);

  /// The card without its tail.
  double get bodyHeight =>
      (anchorY - _gap - tail - _top).clamp(_minBody, _maxBody).toDouble();

  /// The card with its tail.
  double get height => bodyHeight + tail;

  static const _floatingHeight = 300.0;

  /// A card with no tail, floating above the bottom of the screen: how a
  /// county shows, since a county has no single spot to point at.
  Rect floatingRect(double bottomPad) {
    final w = math.min(420.0, screen.width - margin * 2);
    return Rect.fromLTWH(
      (screen.width - w) / 2,
      screen.height - bottomPad - _floatingHeight,
      w,
      _floatingHeight,
    );
  }

  /// The card's box when its tail points at [anchor], kept on screen.
  Rect cardRect(Offset anchor) {
    final left = anchor.dx - width / 2;
    final clamped = math.max(
      margin,
      math.min(left, screen.width - margin - width),
    );
    return Rect.fromLTWH(clamped, anchor.dy - _gap - height, width, height);
  }

  /// Where the tail sits along the card, from its left edge.
  double tailX(Offset anchor) {
    final rect = cardRect(anchor);
    return (anchor.dx - rect.left).clamp(36.0, rect.width - 36.0).toDouble();
  }

  /// Camera padding that puts the map's centre, and so the pin, at
  /// [anchorY]: the centre of the padded area sits there.
  ({double top, double bottom}) get cameraPadding {
    final shift = 2 * anchorY - screen.height;
    return shift >= 0 ? (top: shift, bottom: 0) : (top: 0, bottom: -shift);
  }
}
