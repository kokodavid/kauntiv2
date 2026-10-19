import 'package:flutter/material.dart';

import '../domain/county_badge_detail.dart';
import '../domain/passport_county.dart';
import '../domain/passport_level.dart';
import '../domain/passport_progress.dart';
import 'passport_dates.dart';
import 'passport_medallion.dart';
import 'passport_palette.dart';
import 'passport_stamp_row.dart';
import 'passport_text.dart';

/// The top of a county page: its number, region, medallion in the level
/// ring, name, level chip and the five stamps.
class PassportHeroCard extends StatelessWidget {
  const PassportHeroCard({
    super.key,
    required this.county,
    required this.detail,
    required this.progress,
  });

  final PassportCounty county;
  final CountyBadgeDetail detail;
  final PassportProgress progress;

  @override
  Widget build(BuildContext context) {
    final level = county.level;
    final since = detail.earnedAt ?? detail.lastPassAt;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: level.tint,
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'No. ${county.number}',
                      style: passportText(
                        11,
                        weight: FontWeight.w700,
                        color: PassportInk.secondary,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      county.region.label.toUpperCase(),
                      style: passportText(
                        11,
                        weight: FontWeight.w600,
                        color: PassportInk.tertiary,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: level == PassportLevel.gold
                      ? const BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x2EC99A1A),
                              spreadRadius: 8,
                            ),
                          ],
                        )
                      : const BoxDecoration(),
                  child: PassportMedallion(
                    county: county.county,
                    level: level,
                    size: 112,
                    ringWidth: 3,
                    gap: 5,
                    matColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              children: [
                Text(
                  county.name,
                  textAlign: TextAlign.center,
                  style: passportText(26, weight: FontWeight.w700, height: 1.15),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    _LevelChip(level: level),
                    Text(
                      since == null
                          ? 'No visits yet'
                          : 'since ${passportDate(since)}',
                      style: passportText(12.5, weight: FontWeight.w500, color: PassportInk.tertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                PassportStampRow(progress: progress, detail: detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final PassportLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: level.tint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level.label,
        style: passportText(12, weight: FontWeight.w700, color: level.text),
      ),
    );
  }
}
