import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/badge_collection.dart';
import 'county_badge_medallion.dart';

/// The badge as a coin that can spin: a few fast turns about its vertical
/// axis, slowing to land on its front (with a little lift as it starts).
/// Spins once on start when [spinOnStart], but only after the sheet it's
/// in has finished sliding up (one motion at a time); tapping an earned
/// coin spins it again. Stays still when the phone asks for reduced
/// motion.
class BadgeCoin extends StatefulWidget {
  const BadgeCoin({
    super.key,
    required this.badge,
    required this.size,
    this.spinOnStart = false,
    this.onSpinningChanged,
  });

  final CountyBadge badge;
  final double size;
  final bool spinOnStart;

  /// True while spinning (the sheet holds Share until it lands).
  final ValueChanged<bool>? onSpinningChanged;

  static const duration = Duration(milliseconds: 2200);
  static const turns = 2;

  @override
  State<BadgeCoin> createState() => _BadgeCoinState();
}

class _BadgeCoinState extends State<BadgeCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: BadgeCoin.duration,
  )..addStatusListener(_onStatus);
  late final Animation<double> _turn = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _lift = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.06), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 1.06, end: 1), weight: 75),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  bool _started = false;

  /// A short beat between the sheet settling and the coin spinning.
  static const _settle = Duration(milliseconds: 150);
  Timer? _delay;
  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && widget.spinOnStart) {
      _started = true;
      _spinWhenShown();
    }
  }

  @override
  void didUpdateWidget(BadgeCoin oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The "first open?" answer can arrive a moment after the sheet.
    if (!_started && widget.spinOnStart && !oldWidget.spinOnStart) {
      _started = true;
      _spinWhenShown();
    }
  }

  /// Waits for the sheet's slide-up to finish, then spins.
  void _spinWhenShown() {
    final route = ModalRoute.of(context)?.animation;
    if (route == null || route.status == AnimationStatus.completed) {
      _spinAfterFrame();
      return;
    }
    _routeAnimation = route..addStatusListener(_onRouteStatus);
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _routeAnimation = null;
    _spinAfterFrame();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      widget.onSpinningChanged?.call(true);
    } else if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      widget.onSpinningChanged?.call(false);
    }
  }

  /// Not mid-build: the listener may rebuild the sheet.
  void _spinAfterFrame() => WidgetsBinding.instance.addPostFrameCallback((_) {
    _delay?.cancel();
    _delay = Timer(_settle, () {
      if (mounted) _spin();
    });
  });

  void _spin() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    unawaited(_controller.forward(from: 0));
  }

  @override
  void dispose() {
    _delay?.cancel();
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;
    Widget face({required bool back}) => CountyBadgeMedallion(
      county: badge.county,
      earned: badge.isEarned,
      size: widget.size,
      back: back,
    );
    final front = face(back: false);
    final reverse = face(back: true);
    return GestureDetector(
      onTap: badge.isEarned && !_controller.isAnimating ? _spin : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _turn.value * BadgeCoin.turns * 2 * math.pi;
          // The back faces the viewer between a quarter and three
          // quarters of each turn.
          final cycle = angle % (2 * math.pi);
          final showsBack = cycle > math.pi / 2 && cycle < math.pi * 1.5;
          final lift = _controller.isAnimating ? _lift.value : 1.0;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..multiply(Matrix4.diagonal3Values(lift, lift, 1))
              ..rotateY(angle),
            child: showsBack
                // Turned once more so the back doesn't read mirrored.
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: reverse,
                  )
                : front,
          );
        },
      ),
    );
  }
}
