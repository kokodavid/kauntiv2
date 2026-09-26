import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/county_tier.dart';
import '../../../design/app_colors.dart';
import '../domain/badge_collection.dart';

/// "20 of 47 counties claimed": the count, one bar segment per county
/// (claimed ones tall and blue), and the share of Kenya and what's left
/// (Figma 491:2499).
class BadgesHeroCard extends StatelessWidget {
  const BadgesHeroCard({super.key, required this.collection});

  final BadgeCollection collection;

  static const _muted = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 12,
    height: 20 / 12,
    color: AppColors.mutedForeground,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.lockedFill),
        gradient: const RadialGradient(
          radius: 1.2,
          colors: [Colors.white, Colors.white, Color(0x99FFFFFF)],
          stops: [0, 0.68, 1],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 14, 13, 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE6F3FF), Color(0x14DBEEFF)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${collection.claimed}',
                  style: const TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontWeight: FontWeight.w200,
                    fontSize: 56,
                    height: 1,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'of ${collection.total} counties claimed',
                  style: _muted.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _SegmentBar(
                filled: collection.claimed,
                total: collection.total,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${collection.percentOfKenya}% OF KENYA', style: _muted),
                  Text('${collection.left} LEFT', style: _muted),
                ],
              ),
            ),
            if (collection.nextTier case final next?)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                child: Text(
                  _nextLine(collection.claimed, next),
                  style: _muted.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "3 more counties to Msafiri" (the next medal).
String _nextLine(int claimed, CountyTier next) {
  final more = next.counties - claimed;
  return '$more more ${more == 1 ? 'county' : 'counties'} to ${next.label}';
}

/// One thin bar per county: claimed ones 20 px and blue, the rest 13 px
/// and pale, bottom-aligned.
class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < total; i++)
            Container(
              width: 4,
              height: i < filled ? 20 : 13,
              decoration: BoxDecoration(
                color: i < filled ? AppColors.accent : AppColors.trackInactive,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }
}
