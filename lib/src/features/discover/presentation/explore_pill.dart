import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import 'explore_styles.dart';

/// The rounded filter pill used by Explore's tabs and County Detail's
/// place filters: accent fill when selected, outlined white otherwise.
class ExplorePill extends StatelessWidget {
  const ExplorePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.horizontalPadding = 8,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : AppColors.exploreSurface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.exploreBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 7.25,
          ),
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: ExploreStyles.tabChip(selected: selected),
          ),
        ),
      ),
    );
  }
}
