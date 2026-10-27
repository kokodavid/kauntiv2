import 'package:flutter/material.dart';

import '../domain/passport_county.dart';
import '../domain/passport_level.dart';
import '../domain/passport_progress.dart';
import '../domain/passport_rules.dart';
import 'passport_dates.dart';
import 'passport_later_card.dart';
import 'passport_lock_note.dart';
import 'passport_milestone_rows.dart';
import 'passport_palette.dart';
import 'passport_requirements.dart';
import 'passport_text.dart';
import 'passport_visit_meter.dart';

/// "Next stamp": what the county needs for its next level. One variant per
/// level; a metal stamp that can't be earned yet shows as "Later".
class PassportNextStampCard extends StatelessWidget {
  const PassportNextStampCard({
    super.key,
    required this.county,
    required this.progress,
    this.rules = PassportRules.standard,
  });

  final PassportCounty county;
  final PassportProgress progress;

  /// The thresholds the "To earn" box reads.
  final PassportRules rules;

  @override
  Widget build(BuildContext context) {
    final next = progress.next;
    if (next == null) return _Complete(county: county);
    if (progress.isLater) {
      return PassportLaterCard.later(
        county: county,
        next: next,
        progress: progress,
      );
    }
    final lock = progress.lock;
    final kicker = county.level == PassportLevel.none
        ? 'FIRST STAMP · PASSED THROUGH'
        : 'NEXT STAMP · ${next.label.toUpperCase()}'
              '${lock == null ? '' : ' · LOCKED'}';
    return _Shell(
      kicker: kicker,
      kickerColor: lock != null
          ? PassportInk.tertiary
          : next.isMetal
          ? next.text
          : PassportInk.blueDeep,
      collapsible: county.level != PassportLevel.none,
      title: switch (county.level) {
        PassportLevel.none => 'Travel into ${county.name}',
        PassportLevel.passedThrough => 'Stay a while in ${county.name}',
        _ when lock != null =>
          '${next.label} is not open in ${county.name} yet',
        _ => 'Keep going in ${county.name}',
      },
      children: [
        if (lock != null)
          PassportLockNote(county: county.name, lock: lock)
        else
          PassportRequirements(next: next, county: county.name, rules: rules),
        ...switch (county.level) {
          PassportLevel.none => const <Widget>[],
          PassportLevel.passedThrough => _passedThrough(),
          _ => [
            const SizedBox(height: 14),
            PassportMilestoneRows(rows: progress.rows, next: next),
          ],
        },
      ],
    );
  }

  List<Widget> _passedThrough() => [
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Longest visit',
              style: passportText(12, color: PassportInk.secondary),
            ),
          ),
          Text(
            '${passportDuration(progress.longestVisit)} of '
            '${passportDuration(progress.exploredStay)}',
            style: passportText(12, weight: FontWeight.w700),
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

class _Shell extends StatefulWidget {
  const _Shell({
    required this.kicker,
    required this.kickerColor,
    required this.title,
    required this.children,
    this.collapsible = true,
  });

  final String kicker;
  final Color kickerColor;
  final String title;
  final List<Widget> children;

  /// False for the first stamp: what to do is the whole point, so it stays
  /// open.
  final bool collapsible;

  @override
  State<_Shell> createState() => _ShellState();
}

/// Closed by default; tapping the header opens the details. Closed, it shows
/// just the kicker and title.
class _ShellState extends State<_Shell> {
  late bool _open = !widget.collapsible;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.collapsible
                ? () => setState(() => _open = !_open)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.kicker,
                          style: passportText(
                            10,
                            weight: FontWeight.w600,
                            color: widget.kickerColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.title,
                          style: passportText(
                            15,
                            weight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.collapsible) ...[
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: PassportInk.tertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.children,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
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
    style: passportText(12.5, color: PassportInk.secondary, height: 1.45),
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
