import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/passport_level.dart';
import 'passport_palette.dart';

/// One segment per county: stamped counties stand tall in their level's
/// colour, the rest sit low and pale, bottom-aligned. Used on the Traveller
/// card and the Passport share card.
class PassportLevelBar extends StatelessWidget {
  const PassportLevelBar({
    super.key,
    required this.levels,
    this.height = 20,
    this.offHeight = 13,
    this.onPhoto = false,
  });

  /// Every county's level, in the order to draw them.
  final List<PassportLevel> levels;
  final double height;
  final double offHeight;

  /// Over a photo: unstamped segments are a faint white and Passed Through
  /// a lighter grey, matching [PassportKenyaMap.onPhoto].
  final bool onPhoto;

  Color _colour(PassportLevel level) => switch (level) {
    PassportLevel.none =>
      onPhoto ? Colors.white.withValues(alpha: 0.28) : AppColors.trackInactive,
    PassportLevel.passedThrough when onPhoto => const Color(0xFFD4D4D8),
    _ => level.ring,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < levels.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(
              child: Container(
                height: levels[i] == PassportLevel.none ? offHeight : height,
                decoration: BoxDecoration(
                  color: _colour(levels[i]),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
