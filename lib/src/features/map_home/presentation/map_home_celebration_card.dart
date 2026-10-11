import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// The win: "Nakuru is yours", with a bar of one segment per county.
/// Also used for "All 47 counties".
class MapHomeCelebrationCard extends StatelessWidget {
  const MapHomeCelebrationCard({
    super.key,
    required this.headline,
    required this.meta,
    required this.claimed,
    required this.total,
  });

  final String headline;
  final String meta;
  final int claimed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$headline. $meta',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headline,
              style: AppTypeScale.sectionTitle.copyWith(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              meta,
              style: AppTypeScale.body.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 14),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < total; i++) ...[
                    if (i > 0) const SizedBox(width: 1.5),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: i < claimed
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
