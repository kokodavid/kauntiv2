import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import 'planned_example_day.dart';

/// The looping example on the empty Planned page: three collapsed day
/// cards that cross-fade in place, one at a time, with dots under them.
/// Tap to pause and resume. With reduced motion it shows Day 1 only, and it
/// stops while its tab is not visible.
class PlannedExampleLoop extends StatefulWidget {
  const PlannedExampleLoop({
    super.key,
    this.days = exampleDays,
    this.hold = const Duration(milliseconds: 2400),
    this.fade = const Duration(milliseconds: 600),
  });

  final List<ExampleDay> days;

  /// How long each day stays up, and how long the cross-fade takes.
  final Duration hold;
  final Duration fade;

  @override
  State<PlannedExampleLoop> createState() => _PlannedExampleLoopState();
}

class _PlannedExampleLoopState extends State<PlannedExampleLoop> {
  int _index = 0;
  bool _paused = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    _timer = null;
    final still =
        MediaQuery.of(context).disableAnimations || !TickerMode.of(context);
    if (still) return;
    _timer = Timer.periodic(widget.hold, (_) {
      if (!_paused && mounted) {
        setState(() => _index = (_index + 1) % widget.days.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _paused = !_paused),
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: Stack(
              children: [
                Positioned(
                  left: 20,
                  right: 20,
                  top: 18,
                  height: 140,
                  child: Opacity(opacity: 0.7, child: _peekCard()),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  top: 0,
                  bottom: 14,
                  child: Semantics(
                    label:
                        'Example plan, day ${_index + 1} of '
                        '${widget.days.length}',
                    child: AnimatedSwitcher(
                      duration: widget.fade,
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_index),
                        child: ExcludeSemantics(
                          child: ExampleDayCard(day: widget.days[_index]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.days.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: i == _index ? 18 : 6,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? AppColors.foreground
                          : AppColors.lockedStroke,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _peekCard() => Container(
    decoration: BoxDecoration(
      color: AppColors.exploreSurface,
      border: Border.all(color: AppColors.exploreBorder),
      borderRadius: BorderRadius.circular(16),
    ),
  );
}
