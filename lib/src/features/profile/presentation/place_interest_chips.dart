import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/place_interest.dart';

/// The place-interest chips, shared by setup step 2 and the standalone
/// Interests editor. Selected chips are solid blue with a check, so the
/// state never relies on colour alone, and each reads to a screen reader
/// as "Waterfalls and hikes, checkbox, checked".
class PlaceInterestChips extends StatelessWidget {
  const PlaceInterestChips({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final List<PlaceInterest> selected;
  final ValueChanged<PlaceInterest> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final interest in PlaceInterest.values)
          _InterestChip(
            interest: interest,
            isSelected: selected.contains(interest),
            onTap: () => onToggle(interest),
          ),
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.interest,
    required this.isSelected,
    required this.onTap,
  });

  final PlaceInterest interest;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected
        ? AppColors.accentForeground
        : AppColors.foreground;
    return Semantics(
      checked: isSelected,
      inMutuallyExclusiveGroup: false,
      button: true,
      label: interest.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: isSelected ? AppColors.accent : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? AppColors.accent : AppColors.backButtonBorder,
            width: 1.5,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? Icons.check : interest.icon,
                    size: 18,
                    color: foreground,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    interest.label,
                    style: AppTextStyles.buttonLabelSecondary.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
