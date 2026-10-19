import 'package:flutter/material.dart';

import '../domain/passport_level.dart';
import '../domain/passport_progress.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// The milestone lines under a metal stamp's goal: label, "v of t" and one
/// segment per step. With [dimmed] (a stamp that can't be earned yet) the
/// counts are hidden and the segments stay empty.
class PassportMilestoneRows extends StatelessWidget {
  const PassportMilestoneRows({
    super.key,
    required this.rows,
    required this.next,
    required this.county,
    this.dimmed = false,
  });

  final List<PassportMilestoneRow> rows;
  final PassportLevel next;
  final String county;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows) ...[
          _Row(row: row, color: next.ring, dimmed: dimmed),
          if (row.adjustedFrom != null && !dimmed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                row.label == 'Categories'
                    ? 'Adjusted from ${row.adjustedFrom}: it can\'t ask for '
                          'more categories than places.'
                    : 'Adjusted from ${row.adjustedFrom}: $county has '
                          '${row.target} reviewed '
                          '${row.target == 1 ? 'place' : 'places'} so far.',
                style: passportText(11.5, weight: FontWeight.w500, color: PassportInk.tertiary),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.color, required this.dimmed});

  final PassportMilestoneRow row;
  final Color color;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final filled = dimmed ? 0 : row.value.clamp(0, row.target);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                row.label,
                style: passportText(
                  13.5,
                  weight: FontWeight.w500,
                  color: dimmed ? PassportInk.disabled : PassportInk.primary,
                ),
              ),
            ),
            if (!dimmed)
              Text(
                '${row.value} of ${row.target}',
                style: passportText(
                  12.5,
                  weight: FontWeight.w600,
                  color: row.isDone ? color : PassportInk.tertiary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < row.target; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < filled ? color : PassportInk.segmentOff,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
