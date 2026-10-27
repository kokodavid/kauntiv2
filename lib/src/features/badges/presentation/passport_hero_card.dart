import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/county_badge_detail.dart';
import '../domain/passport_county.dart';
import '../domain/passport_level.dart';
import '../domain/passport_progress.dart';
import 'passport_dates.dart';
import 'passport_medallion.dart';
import 'passport_palette.dart';
import 'passport_stamp_art.dart';
import 'passport_stamp_row.dart';
import 'passport_text.dart';

/// The top of a county page, set straight on the page: the medallion in its
/// level ring, the name, "Level · date", and the five-step stamp row.
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
    return Column(
      children: [
        const SizedBox(height: 14),
        if (PassportStampArt.has(county))
          PassportStampArt(county: county, extent: 150)
        else
          DecoratedBox(
            decoration: level == PassportLevel.gold
                ? const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x2EC99A1A), spreadRadius: 8),
                    ],
                  )
                : const BoxDecoration(),
            child: PassportMedallion(
              county: county.county,
              level: level,
              size: 104,
              ringWidth: 3,
              gap: 5,
              matColor: AppColors.pageBackground,
            ),
          ),
        const SizedBox(height: 14),
        Text(
          county.name,
          textAlign: TextAlign.center,
          style: passportText(21, weight: FontWeight.w700, height: 1.2),
        ),
        const SizedBox(height: 6),
        Text(
          since == null
              ? level.label
              : '${level.label} · ${passportDate(since)}',
          textAlign: TextAlign.center,
          style: passportText(
            15,
            weight: FontWeight.w500,
            color: PassportInk.secondary,
          ),
        ),
        const SizedBox(height: 20),
        PassportStampRow(progress: progress, detail: detail),
      ],
    );
  }
}
