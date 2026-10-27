import 'dart:async';

import 'package:flutter/material.dart';

import 'map_popup_flip.dart';
import 'map_popup_layout.dart';
import 'map_popup_shape.dart';

/// Builds one face of a popup. [flip] turns the card over; [close] closes it.
typedef PopupFaceBuilder =
    Widget Function(VoidCallback flip, VoidCallback close);

/// The card Home's map shows for a tapped place or county, in place of a
/// bottom sheet. A place's card grows out of its pin with a tail pointing
/// back at it; a county's floats up from the bottom. Either turns over on
/// tap to show the details, and shrinks away when closed.
///
/// A touch anywhere outside it closes it and still reaches the map, so a
/// drag or pinch carries on from the same touch.
class RealMapPlacePopup {
  final _host = GlobalKey<_PopupHostState>();
  OverlayEntry? _entry;
  VoidCallback? _onGone;

  bool get isOpen => _entry != null;

  /// Runs when the popup has fully gone after [close].
  set onGone(VoidCallback? callback) => _onGone = callback;

  /// Opens a pin's popup growing from [from] (the pin on screen) to [to]
  /// (where the camera is putting the pin), with a tail at the pin. Without
  /// them it is a floating card ([bottomPad] above the screen's bottom).
  /// Replaces one already open.
  void show(
    BuildContext context, {
    required MapPopupLayout layout,
    required PopupFaceBuilder front,
    required PopupFaceBuilder back,
    required VoidCallback onClose,
    Offset? from,
    Offset? to,
    double bottomPad = 24,
  }) {
    dispose();
    final entry = OverlayEntry(
      builder: (_) => _PopupHost(
        key: _host,
        layout: layout,
        from: from,
        to: to,
        bottomPad: bottomPad,
        front: front,
        back: back,
        onOutside: onClose,
        onGone: _remove,
      ),
    );
    _entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  /// The pin ended up somewhere other than planned (the map couldn't move
  /// that far): slides the card to it.
  void reanchor(Offset anchor) => _host.currentState?.reanchor(anchor);

  /// Shrinks away. [onGone] runs once it has.
  void close() => _host.currentState?.dismiss();

  void _remove() {
    _entry?.remove();
    _entry = null;
    _onGone?.call();
  }

  /// Removes it at once, with no animation and no callback.
  void dispose() {
    _entry?.remove();
    _entry = null;
  }
}

class _PopupHost extends StatefulWidget {
  const _PopupHost({
    super.key,
    required this.layout,
    required this.from,
    required this.to,
    required this.bottomPad,
    required this.front,
    required this.back,
    required this.onOutside,
    required this.onGone,
  });

  final MapPopupLayout layout;
  final Offset? from;
  final Offset? to;
  final double bottomPad;
  final PopupFaceBuilder front;
  final PopupFaceBuilder back;
  final VoidCallback onOutside;
  final VoidCallback onGone;

  @override
  State<_PopupHost> createState() => _PopupHostState();
}

class _PopupHostState extends State<_PopupHost> with TickerProviderStateMixin {
  late final _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final _turnCurve = CurvedAnimation(
    parent: _turn,
    curve: Curves.easeInOutCubic,
  );
  late Offset? _anchor = widget.to;
  Rect _rect = Rect.zero;
  bool _closing = false;

  // Settles without overshoot; closing runs the same curve back.
  static const _openCurve = Cubic(0.22, 0.9, 0.28, 1);

  bool get _floating => widget.to == null;

  @override
  void initState() {
    super.initState();
    unawaited(_grow.forward());
  }

  @override
  void dispose() {
    _turnCurve.dispose();
    _grow.dispose();
    _turn.dispose();
    super.dispose();
  }

  void reanchor(Offset anchor) {
    final current = _anchor;
    if (_closing || current == null || (anchor - current).distance < 2) return;
    setState(() => _anchor = anchor);
  }

  void dismiss() {
    if (_closing) return;
    _closing = true;
    unawaited(_turn.reverse());
    unawaited(_grow.reverse().whenComplete(widget.onGone));
  }

  void _flip() {
    if (_closing) return;
    final showingBack =
        _turn.status == AnimationStatus.completed ||
        _turn.status == AnimationStatus.forward;
    unawaited(showingBack ? _turn.reverse() : _turn.forward());
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) {
                if (!_closing && !_rect.contains(event.localPosition)) {
                  widget.onOutside();
                }
              },
            ),
          ),
          _floating ? _floatingCard() : _pinCard(),
        ],
      ),
    );
  }

  /// A pin's card: grows from the pin to the tail's anchor.
  Widget _pinCard() {
    final layout = widget.layout;
    return TweenAnimationBuilder<Offset>(
      tween: Tween(end: _anchor),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, anchor, _) => AnimatedBuilder(
        animation: _grow,
        builder: (context, _) {
          final t = _eased;
          final at = Offset.lerp(widget.from ?? anchor, anchor, t)!;
          _rect = layout.cardRect(at);
          final tailX = layout.tailX(at);
          return Positioned.fromRect(
            rect: _rect,
            child: Opacity(
              opacity: (t * 2).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.5 + 0.5 * t,
                alignment: Alignment(tailX / _rect.width * 2 - 1, 1),
                child: _card(
                  MapPopupShape(tailX: tailX),
                  MapPopupShape.tailHeight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double get _eased => _grow.status == AnimationStatus.reverse
      ? Curves.easeInCubic.transform(_grow.value)
      : _openCurve.transform(_grow.value);

  /// A county's card: rises from the bottom with no tail.
  Widget _floatingCard() {
    _rect = widget.layout.floatingRect(widget.bottomPad);
    return AnimatedBuilder(
      animation: _grow,
      builder: (context, _) {
        final t = _eased;
        return Positioned.fromRect(
          rect: _rect,
          child: Opacity(
            opacity: (t * 2).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 32),
              child: Transform.scale(
                scale: 0.94 + 0.06 * t,
                alignment: Alignment.bottomCenter,
                child: _card(const MapPopupShape(tailX: 0, tail: 0), 0),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _card(ShapeBorder shape, double tail) {
    void close() => widget.onOutside();
    return Material(
      type: MaterialType.transparency,
      child: MapPopupFlip(
        progress: _turnCurve,
        front: _face(shape, widget.front(_flip, close)),
        back: _face(
          shape,
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _flip,
            child: widget.back(_flip, close),
          ),
        ),
      ),
    );
  }

  Widget _face(ShapeBorder shape, Widget child) => DecoratedBox(
    decoration: ShapeDecoration(
      color: Colors.white,
      shape: shape,
      shadows: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 26,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: child,
  );
}
