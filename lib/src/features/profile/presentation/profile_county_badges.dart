import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/county_badge_medallion.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../../badges/domain/badge_collection.dart';

class ProfileCountyBadges extends StatelessWidget {
  const ProfileCountyBadges({
    super.key,
    required this.collection,
    required this.onOpenBadges,
  });

  final AsyncValue<BadgeCollection> collection;
  final VoidCallback onOpenBadges;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'County badges',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: onOpenBadges,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See all'),
                  Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 78,
          child: collection.when(
            loading: () => const Center(
              child: AppProgressIndicator(color: AppColors.accent, radius: 10),
            ),
            error: (error, stackTrace) => const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Badges are unavailable. Open the collection to retry.',
              ),
            ),
            // `value.badges` is already earned-first (BadgeCollection's
            // constructor), so this is a mix of the counties you've
            // claimed and a teaser of the next ones -- a badge that
            // isn't earned yet still gets a medallion, drawn in its
            // existing locked (grey) style, rather than being filtered
            // out and leaving the row to just stop after the ones
            // you've earned.
            data: (value) {
              final display = value.badges.take(6);
              if (display.isEmpty) {
                return const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'County badges will show up here once counties load.',
                    style: TextStyle(color: AppColors.mutedForeground),
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: display.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final badge = display.elementAt(index);
                  return SizedBox(
                    width: 58,
                    child: Column(
                      children: [
                        CountyBadgeMedallion(
                          county: badge.county,
                          earned: badge.isEarned,
                          size: 54,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          badge.county.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: badge.isEarned
                                ? AppColors.mutedForeground
                                : AppColors.mutedForeground.withValues(
                                    alpha: 0.7,
                                  ),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
