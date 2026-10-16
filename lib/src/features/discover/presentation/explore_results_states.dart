import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/place_type.dart';
import '../../../core/widgets/place_type_style.dart';
import '../../../design/app_colors.dart';
import 'explore_pill_counts.dart';

/// A small caps label with a rule, used for "CLOSEST ANYWAY".
class ExploreRuleLabel extends StatelessWidget {
  const ExploreRuleLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(
          fontFamily: AppTypeScale.family,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: .5,
          color: AppColors.mutedForeground,
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: SizedBox(
          height: 1,
          child: ColoredBox(color: AppColors.exploreBorder),
        ),
      ),
    ],
  );
}

/// The one fix offered when a distance limit leaves nothing.
class ExplorePrimaryButton extends StatelessWidget {
  const ExplorePrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.accent,
    shape: const StadiumBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: SizedBox(
        height: 52,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ),
  );
}

/// "Similar places" and two related category pills under a thin category.
class ExploreSimilarTypes extends StatelessWidget {
  const ExploreSimilarTypes({
    super.key,
    required this.types,
    required this.onPick,
  });

  final List<({PlaceType type, int count})> types;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          const Text(
            'Similar places',
            style: TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in types)
                Material(
                  color: AppColors.exploreSurface,
                  shape: const StadiumBorder(
                    side: BorderSide(color: AppColors.exploreBorder),
                  ),
                  child: InkWell(
                    onTap: () => onPick(item.type.key),
                    customBorder: const StadiumBorder(),
                    child: SizedBox(
                      height: 36,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.type.icon,
                              size: 17,
                              color: AppColors.mutedForeground,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              explorePillLabel(
                                item.type.pluralLabel,
                                item.count,
                              ),
                              style: AppTypeScale.pill.copyWith(
                                color: AppColors.exploreMutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
