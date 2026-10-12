import 'package:flutter/material.dart';

import '../../../core/widgets/choice_tile_grid.dart';
import '../../../core/widgets/interest_icons.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../profile/domain/place_interest.dart';
import 'onboarding_shell.dart';

/// Setup step 2 of 3: what kinds of places the user likes. Optional:
/// Continue wakes on the first pick, and "Skip for now" is always in the
/// same slot. No minimum and no maximum.
class OnboardingInterestsPage extends StatelessWidget {
  const OnboardingInterestsPage({
    super.key,
    required this.selected,
    required this.isSaving,
    required this.onToggle,
    required this.onContinue,
    required this.onSkip,
    required this.onBack,
  });

  final List<PlaceInterest> selected;
  final bool isSaving;
  final ValueChanged<PlaceInterest> onToggle;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  /// The line under the tiles: what the count means, never an error. It
  /// also says picks lean the suggestions, not filter them.
  static String hint(int count) {
    if (count == 0) return 'Pick any number, or skip for now.';
    return '$count picked. For you leans toward these and still shows '
        'the rest.';
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      step: 2,
      title: 'What do you like to see?',
      subtitle: const Text(
        "Each county you enter comes with places to stop. Pick what's worth "
        'a stop for you.',
      ),
      onBack: onBack,
      primaryLabel: 'Continue',
      onPrimary: selected.isEmpty ? null : onContinue,
      secondaryLabel: 'Skip for now',
      onSecondary: onSkip,
      isBusy: isSaving,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChoiceTileGrid<PlaceInterest>(
              options: PlaceInterest.values,
              selected: selected,
              labelOf: (interest) => interest.label,
              iconOf: (interest) => interestIconForKey(interest.key),
              onToggle: onToggle,
            ),
            const SizedBox(height: 14),
            Text(
              hint(selected.length),
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
