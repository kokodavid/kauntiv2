import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// A chapter heading (design "Field Chapter v2"): an optional KICKER, a
/// 16 pt title and an optional "See all" link. A group of chapters shares one
/// [ExploreGroupLabel] instead of repeating the kicker on each.
class ExploreChapterHeader extends StatelessWidget {
  const ExploreChapterHeader({
    super.key,
    required this.kicker,
    required this.title,
    this.action,
    this.onAction,
  });

  final String kicker;
  final String title;

  /// Link text on the right ("See all"); hidden when null.
  final String? action;
  final VoidCallback? onAction;

  static const _small = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: AppTypeScale.labelSize,
    fontWeight: FontWeight.w600,
    letterSpacing: AppTypeScale.labelTracking,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kicker.isNotEmpty) ...[
                Text(
                  kicker.toUpperCase(),
                  style: _small.copyWith(color: AppColors.mutedForeground),
                ),
                const SizedBox(height: 5),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTypeScale.family,
                  fontSize: 16,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: AppColors.exploreText,
                ),
              ),
            ],
          ),
        ),
        if (action != null)
          // Padding, not a 44 pt box: a taller link would stretch the whole
          // heading row and open a gap above the title.
          InkWell(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 0, 6),
              child: Text(
                action!,
                style: const TextStyle(
                  fontFamily: AppTypeScale.family,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The one caps label above a group of chapters ("FOR YOU", "MORE PLACES"):
/// accent blue and a touch larger than a kicker, set close above the first
/// chapter's title.
class ExploreGroupLabel extends StatelessWidget {
  const ExploreGroupLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: AppTypeScale.family,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.accent,
      ),
    ),
  );
}
