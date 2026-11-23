import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import 'planned_example_day.dart';

/// The looping example on the empty Planned page: three collapsed day
/// cards. The front card drops away and the next one rises out of the
/// stack behind it (a deck swap, no overlapping fade). Tap to pause and
/// resume. With reduced motion it shows Day 1 only, and it stops while its
/// tab is not visible.
class PlannedExampleLoop extends StatefulWidget {
  const PlannedExampleLoop({
    super.key,
    this.days = exampleDays,
    this.hold = const Duration(milliseconds: 4000),
    this.swap = const Duration(milliseconds: 1300),
  });

  final List<ExampleDay> days;

  /// How long each day stays up, and how long the swap takes.
  final Duration hold;
  final Duration swap;

  @override
  State<PlannedExampleLoop> createState() => _PlannedExampleLoopState();
}

class _PlannedExampleLoopState extends State<PlannedExampleLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swap = AnimationController(
    vsync: this,
    duration: widget.swap,
  );
  int _index = 0;
  bool _swapping = false;
  bool _paused = false;
  Timer? _timer;

  int get _next => (_index + 1) % widget.days.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    _timer = null;
    final still =
        MediaQuery.of(context).disableAnimations ||
        !TickerMode.valuesOf(context).enabled;
    if (still) return;
    _timer = Timer.periodic(widget.hold, (_) => _advance());
  }

  void _advance() {
    if (_paused || _swapping || !mounted) return;
    setState(() => _swapping = true);
    unawaited(
      _swap.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        setState(() {
          _index = _next;
          _swapping = false;
        });
      }),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _swap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _paused = !_paused),
      child: SizedBox(
        height: 170,
        child: Semantics(
          label: 'Example plan, day ${_index + 1} of ${widget.days.length}',
          child: ExcludeSemantics(
            child: Stack(
              children: [
                Positioned(
                  left: 20,
                  right: 20,
                  top: 18,
                  height: 140,
                  child: _peekCard(),
                ),
                if (_swapping) _incoming(widget.days[_next]),
                _front(widget.days[_index]),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  /// The card on top. While swapping it drops and fades out.
  Widget _front(ExampleDay day) => Positioned(
    left: 8,
    right: 8,
    top: 0,
    bottom: 14,
    child: AnimatedBuilder(
      animation: _swap,
      builder: (context, child) {
        final t = _swapping
            ? Curves.easeInOut.transform(
                const Interval(0, 0.85).transform(_swap.value),
              )
            : 0.0;
        return Opacity(
          opacity: 1 - t,
          child: Transform.translate(
            offset: Offset(0, 14 * t),
            child: Transform.scale(scale: 1 - 0.02 * t, child: child),
          ),
        );
      },
      child: ExampleDayCard(key: ValueKey(day.number), day: day),
    ),
  );

  /// The next card, starting where the peek card sits and rising to the
  /// front as the old one leaves.
  Widget _incoming(ExampleDay day) => Positioned(
    left: 8,
    right: 8,
    top: 0,
    bottom: 14,
    child: AnimatedBuilder(
      animation: _swap,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(
          const Interval(0.15, 1).transform(_swap.value),
        );
        return Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: Transform.scale(
            scale: 0.95 + 0.05 * t,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: ExampleDayCard(key: ValueKey(day.number), day: day),
    ),
  );

  Widget _peekCard() => Opacity(
    opacity: 0.7,
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.exploreSurface,
        border: Border.all(color: AppColors.exploreBorder),
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
