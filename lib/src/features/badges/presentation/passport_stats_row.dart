import 'package:flutter/material.dart';

import '../domain/county_badge_detail.dart';
import 'passport_dates.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// "Your time in {county}": three tiles of what the user has done there.
class PassportStatsRow extends StatelessWidget {
  const PassportStatsRow({
    super.key,
    required this.county,
    required this.detail,
  });

  final String county;
  final CountyBadgeDetail detail;

  @override
  Widget build(BuildContext context) {
    final visits = detail.exploredVisits + detail.passCount;
    final last = detail.lastVisitedAt ?? detail.lastPassAt;
    final km = detail.journeyMeters / 1000;
    final tiles = [
      (
        value: visits == 0 ? '-' : '$visits visit${visits == 1 ? '' : 's'}',
        label: detail.exploredMonths == 0
            ? 'Total'
            : '${detail.exploredMonths} month${detail.exploredMonths == 1 ? '' : 's'}',
      ),
      (value: last == null ? '-' : passportDay(last), label: 'Last here'),
      (
        value: detail.journeys == 0
            ? '-'
            : '${detail.journeys} trip${detail.journeys == 1 ? '' : 's'}',
        label: detail.journeys == 0 ? 'Recorded' : '${km.round()} km',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'Your time in $county',
            style: passportText(14, weight: FontWeight.w700),
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        tiles[i].value,
                        style: passportText(13.5, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tiles[i].label,
                        style: passportText(11, color: PassportInk.tertiary),
                      ),
                    ],
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
