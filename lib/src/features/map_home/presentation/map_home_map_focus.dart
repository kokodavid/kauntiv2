import 'dart:async';

import 'package:flutter/material.dart';

/// Tracks whether the user is working the map (dragging or pinching it) so
/// Home can clear the header and sheet out of the way. A plain tap does not
/// count. Once the last finger lifts, it waits [settle] before the chrome
/// returns, and a new touch inside that wait keeps it hidden.
///
/// Plain state, not a notifier: [onChanged] tells the owning widget to
/// rebuild when [isBusy] flips.
class MapHomeMapFocus {
  MapHomeMapFocus({this.settle = const Duration(seconds: 3), this.onChanged});

  final Duration settle;

  /// Called whenever [isBusy] changes.
  final VoidCallback? onChanged;

  /// How far a finger must travel before it counts as working the map.
  static const slop = 12.0;

  final _down = <int, Offset>{};
  bool _engaged = false;
  Timer? _timer;

  /// True while the map is being worked and through the [settle] wait.
  bool get isBusy => _engaged;

  void down(int pointer, Offset position) {
    _timer?.cancel();
    _down[pointer] = position;
    if (_down.length > 1) _engage();
  }

  void move(int pointer, Offset position) {
    final start = _down[pointer];
    if (start != null && (position - start).distance > slop) _engage();
  }

  void end(int pointer) {
    _down.remove(pointer);
    if (_down.isNotEmpty || !_engaged) return;
    _timer?.cancel();
    _timer = Timer(settle, _release);
  }

  void _engage() {
    _timer?.cancel();
    if (_engaged) return;
    _engaged = true;
    onChanged?.call();
  }

  void _release() {
    if (_down.isNotEmpty || !_engaged) return;
    _engaged = false;
    onChanged?.call();
  }

  void dispose() => _timer?.cancel();
}

/// Reports the touches that reach the map [child] to [focus]. It only
/// listens, so the map still gets every gesture.
class MapHomeMapTouchSensor extends StatelessWidget {
  const MapHomeMapTouchSensor({
    super.key,
    required this.focus,
    required this.child,
  });

  final MapHomeMapFocus focus;
  final Widget child;

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) => focus.down(e.pointer, e.position),
    onPointerMove: (e) => focus.move(e.pointer, e.position),
    onPointerUp: (e) => focus.end(e.pointer),
    onPointerCancel: (e) => focus.end(e.pointer),
    child: child,
  );
}

/// Fades [child] out (and stops it taking touches, so they reach the map
/// underneath) while [focus] is busy. With no [focus] it is just [child].
/// Rebuilt by whoever owns [focus] (see [MapHomeMapFocus.onChanged]).
class MapHomeFocusFade extends StatelessWidget {
  const MapHomeFocusFade({super.key, required this.focus, required this.child});

  final MapHomeMapFocus? focus;
  final Widget child;

  static const duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final map = focus;
    if (map == null) return child;
    return IgnorePointer(
      ignoring: map.isBusy,
      child: AnimatedOpacity(
        opacity: map.isBusy ? 0 : 1,
        duration: duration,
        child: child,
      ),
    );
  }
}
