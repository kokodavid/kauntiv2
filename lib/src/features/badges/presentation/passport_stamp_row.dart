import 'package:flutter/material.dart';

import '../domain/county_badge_detail.dart';
import '../domain/passport_level.dart';
import '../domain/passport_progress.dart';
import 'passport_dates.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// The five stamps of a county page as a stepper: a filled circle with a
/// check for each one earned, a ringed dot for the next, and a pale circle
/// for those still to come, joined by a line that runs blue between earned
/// steps.
class PassportStampRow extends StatelessWidget {
  const PassportStampRow({
    super.key,
    required this.progress,
    required this.detail,
  });

  final PassportProgress progress;
  final CountyBadgeDetail detail;

  static const _stamps = PassportLevel.stamps;
  static const _circle = 26.0;

  /// When a stamp was earned, as far as the data says.
  String? _dateFor(PassportLevel stamp) {
    final at = stamp == PassportLevel.passedThrough
        ? (detail.lastPassAt ?? detail.earnedAt)
        : detail.earnedAt;
    return at == null ? null : passportDay(at);
  }

  @override
  Widget build(BuildContext context) {
    final states = [for (final s in _stamps) progress.stampState(s)];
    bool earned(int i) => states[i] == PassportStampState.earned;
    // A segment is blue only when the steps on both ends are earned.
    Color segment(int i) => earned(i) && earned(i + 1)
        ? PassportLevel.explored.ring
        : PassportInk.track;
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: PassportInk.track)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _stamps.length; i++)
            Expanded(
              child: _Step(
                stamp: _stamps[i],
                state: states[i],
                date: _dateFor(_stamps[i]),
                before: i == 0 ? null : segment(i - 1),
                after: i == _stamps.length - 1 ? null : segment(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.stamp,
    required this.state,
    required this.date,
    required this.before,
    required this.after,
  });

  final PassportLevel stamp;
  final PassportStampState state;
  final String? date;
  final Color? before;
  final Color? after;

  @override
  Widget build(BuildContext context) {
    const size = PassportStampRow._circle;
    final future = state == PassportStampState.future;
    final next = state == PassportStampState.next;
    final label = stamp == PassportLevel.passedThrough
        ? 'Passed\nThrough'
        : stamp.label;
    return Column(
      children: [
        SizedBox(
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  Expanded(child: _Line(color: before)),
                  const SizedBox(width: size),
                  Expanded(child: _Line(color: after)),
                ],
              ),
              _Dot(stamp: stamp, state: state),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: passportText(
            12,
            weight: FontWeight.w700,
            height: 1.25,
            color: future ? PassportInk.disabled : PassportInk.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          switch (state) {
            PassportStampState.earned => date ?? '',
            PassportStampState.next => 'Next',
            PassportStampState.future => '',
          },
          maxLines: 1,
          style: passportText(
            11,
            weight: next ? FontWeight.w600 : FontWeight.w400,
            color: next ? stamp.text : PassportInk.tertiary,
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    height: 3,
    color: color ?? Colors.transparent,
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.stamp, required this.state});

  final PassportLevel stamp;
  final PassportStampState state;

  @override
  Widget build(BuildContext context) {
    const size = PassportStampRow._circle;
    switch (state) {
      case PassportStampState.earned:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: stamp.ring),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
        );
      case PassportStampState.next:
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: stamp.ring, width: 2),
          ),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(shape: BoxShape.circle, color: stamp.ring),
          ),
        );
      case PassportStampState.future:
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: PassportInk.track,
          ),
        );
    }
  }
}
