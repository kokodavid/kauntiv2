import 'package:flutter/material.dart';

import '../domain/passport_county.dart';
import '../domain/passport_level.dart';
import '../domain/passport_progress.dart';
import 'passport_dates.dart';
import 'passport_milestone_rows.dart';
import 'passport_palette.dart';
import 'passport_text.dart';
import 'passport_visit_meter.dart';

/// "Next stamp": what the county needs for its next level. One variant per
/// level; a metal stamp that can't be earned yet shows as "Later".
class PassportNextStampCard extends StatelessWidget {
  const PassportNextStampCard({
    super.key,
    required this.county,
    required this.progress,
  });

  final PassportCounty county;
  final PassportProgress progress;

  @override
  Widget build(BuildContext context) {
    final next = progress.next;
    if (next == null) return _Complete(county: county);
    if (progress.isLater) return _Later(county: county, next: next, progress: progress);
    final kicker = county.level == PassportLevel.none
        ? 'FIRST STAMP · PASSED THROUGH'
        : 'NEXT STAMP · ${next.label.toUpperCase()}';
    return _Shell(
      kicker: kicker,
      kickerColor: next.isMetal ? next.text : PassportInk.blueDeep,
      title: switch (county.level) {
        PassportLevel.none => 'Travel into ${county.name}',
        PassportLevel.passedThrough =>
          'A meaningful visit of two hours or more earns Explored.',
        _ => 'Keep going in ${county.name}',
      },
      children: switch (county.level) {
        PassportLevel.none => [
          const SizedBox(height: 8),
          _Body(
            'The stamp is pressed automatically when you cross in. '
            'Nothing to tap.',
          ),
        ],
        PassportLevel.passedThrough => _passedThrough(),
        _ => [
          const SizedBox(height: 12),
          PassportMilestoneRows(
            rows: progress.rows,
            next: next,
            county: county.name,
          ),
        ],
      },
    );
  }

  List<Widget> _passedThrough() => [
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Longest visit',
              style: passportText(13, color: PassportInk.secondary),
            ),
          ),
          Text(
            '${passportDuration(progress.longestVisit)} of '
            '${passportDuration(progress.exploredStay)}',
            style: passportText(13, weight: FontWeight.w700),
          ),
        ],
      ),
    ),
    const SizedBox(height: 12),
    PassportVisitMeter(fraction: progress.fraction ?? 0),
    const SizedBox(height: 12),
    _Body(
      "Time counts on its own whenever you're here. There's no need to "
      'stay longer than your plans.',
    ),
  ];
}

class _Shell extends StatelessWidget {
  const _Shell({
    required this.kicker,
    required this.kickerColor,
    required this.title,
    required this.children,
  });

  final String kicker;
  final Color kickerColor;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: passportText(
              11,
              weight: FontWeight.w600,
              color: kickerColor,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: passportText(17, weight: FontWeight.w700, height: 1.3)),
          ...children,
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: passportText(13, color: PassportInk.secondary, height: 1.5),
  );
}

class _Complete extends StatelessWidget {
  const _Complete({required this.county});

  final PassportCounty county;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      kicker: 'PAGE COMPLETE',
      kickerColor: PassportLevel.gold.text,
      title: 'You know ${county.name} well',
      children: [
        const SizedBox(height: 8),
        _Body('All five stamps. Gold is the last one on this page.'),
      ],
    );
  }
}

class _Later extends StatelessWidget {
  const _Later({
    required this.county,
    required this.next,
    required this.progress,
  });

  final PassportCounty county;
  final PassportLevel next;
  final PassportProgress progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PassportInk.disabled),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PassportInk.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'LATER',
                  style: passportText(
                    10,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${next.label} is coming',
                style: passportText(
                  12,
                  weight: FontWeight.w600,
                  color: PassportInk.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bronze, Silver and Gold come with place verification',
            style: passportText(17, weight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            "You'll earn them by visiting real places in ${county.name}. "
            'Your Explored stamp stays as it is, and nothing you have '
            'earned goes away.',
            style: passportText(13, color: PassportInk.secondary, height: 1.5),
          ),
          const SizedBox(height: 14),
          PassportMilestoneRows(
            rows: progress.rows,
            next: next,
            county: county.name,
            dimmed: true,
          ),
        ],
      ),
    );
  }
}
