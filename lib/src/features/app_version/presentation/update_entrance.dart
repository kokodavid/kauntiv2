import 'dart:async';

import 'package:flutter/material.dart';

import 'update_widgets.dart';

const _morphMs = 550;
const _totalMs = 750;
const _fadeStart = 450 / _totalMs;

/// Entrance for the forced update screen.
///
/// Coming from the splash ([morph]), the icon starts where the splash drew it
/// (centred, 100 px) and glides to its place on this screen while the halo
/// grows around it, then the rest of the screen fades in. Otherwise, and when
/// the phone asks for reduced motion, the whole screen simpscly fades in.
///
/// While the icon is in flight `flying` is true so the in-flow copy (found
/// through [slotKey]) stays hidden and the swap is invisible.
class UpdateEntrance extends StatefulWidget {
  const UpdateEntrance({
    super.key,
    required this.slotKey,
    required this.morph,
    required this.builder,
  });

  final GlobalKey slotKey;
  final bool morph;

  /// Builds the screen; [flying] is true while the icon copy is in flight.
  final Widget Function(BuildContext context, bool flying) builder;

  @override
  State<UpdateEntrance> createState() => _UpdateEntranceState();
}

class _UpdateEntranceState extends State<UpdateEntrance>
    with SingleTickerProviderStateMixin {
  static const _curve = Cubic(0.2, 0.8, 0.2, 1);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _totalMs),
  );
  late bool _morphing = widget.morph;
  late bool _flying = widget.morph;
  Offset? _target;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _flying = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _start() {
    if (!mounted) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final slot = widget.slotKey.currentContext?.findRenderObject();
    if (!widget.morph || reduce || slot is! RenderBox || !slot.attached) {
      _c.duration = const Duration(milliseconds: 200);
      setState(() {
        _morphing = false;
        _flying = false;
      });
    } else {
      final center = slot.localToGlobal(slot.size.center(Offset.zero));
      setState(() => _target = center);
    }
    unawaited(_c.forward());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = _c.value;
        final fade = _morphing ? const Interval(_fadeStart, 1).transform(v) : v;
        final t = _curve.transform(
          const Interval(0, _morphMs / _totalMs).transform(v),
        );
        final start = Offset(size.width / 2, size.height / 2);
        final center = Offset.lerp(start, _target ?? start, t)!;
        return Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: fade,
                child: widget.builder(context, _flying),
              ),
            ),
            if (_morphing && v < 1)
              Positioned(
                left: center.dx - 100,
                top: center.dy - 100,
                width: 200,
                height: 200,
                child: IgnorePointer(
                  child: Center(
                    child: UpdateAppIcon(size: 100 - 12 * t, halo: t),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Where the icon rests. Hidden while the entrance flies a copy in.
class UpdateIconSlot extends StatelessWidget {
  const UpdateIconSlot({
    super.key,
    required this.slotKey,
    required this.flying,
  });

  final GlobalKey slotKey;
  final bool flying;

  @override
  Widget build(BuildContext context) => Opacity(
    key: slotKey,
    opacity: flying ? 0 : 1,
    child: const UpdateAppIcon(size: 88, halo: 1),
  );
}
