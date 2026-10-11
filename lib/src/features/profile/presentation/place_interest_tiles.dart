import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/place_interest.dart';

/// The place-interest tiles, shared by setup step 2 and the standalone
/// Interests editor: two columns, each tile with its own icon square and a
/// label. A picked tile gets a light-blue fill, a blue border and a check
/// badge, so the state never relies on colour alone. Each reads to a
/// screen reader as "Waterfalls and hikes, checkbox, checked".
class PlaceInterestTiles extends StatelessWidget {
  const PlaceInterestTiles({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final List<PlaceInterest> selected;
  final ValueChanged<PlaceInterest> onToggle;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Room for the check badge that overhangs a tile's corner.
      clipBehavior: Clip.none,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 72,
      ),
      itemCount: PlaceInterest.values.length,
      itemBuilder: (context, index) {
        final interest = PlaceInterest.values[index];
        return _InterestTile(
          interest: interest,
          isSelected: selected.contains(interest),
          onTap: () => onToggle(interest),
        );
      },
    );
  }
}

class _InterestTile extends StatelessWidget {
  const _InterestTile({
    required this.interest,
    required this.isSelected,
    required this.onTap,
  });

  final PlaceInterest interest;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: isSelected,
      button: true,
      label: interest.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.08)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isSelected ? AppColors.accent : AppColors.cardBorder,
                  width: 1.5,
                ),
              ),
              child: InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.pageBackground,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          interest.icon,
                          size: 18,
                          color: isSelected
                              ? AppColors.accentForeground
                              : AppColors.foreground,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          interest.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.buttonLabelSecondary.copyWith(
                            color: AppColors.foreground,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: AppColors.accentForeground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
