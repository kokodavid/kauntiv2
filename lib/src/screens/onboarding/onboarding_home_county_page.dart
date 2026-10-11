import 'package:flutter/material.dart';

import '../../core/widgets/county_badge_medallion.dart';
import '../../counties/county_paths.dart';
import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../widgets/app_county_map.dart';
import '../../widgets/county_picker_sheet.dart';
import 'onboarding_shell.dart';

/// Setup step 1 of 3: pick your home county (setup design v2), inside the
/// shared [OnboardingShell]. The header gives the one-line pitch, so a new
/// user knows the game before picking. Tapping a county's shape on the map
/// selects it; a search bar over the map opens [CountyPickerSheet]; and
/// the pick shows as a card under the map.
///
/// Selecting a home county is required: Continue stays disabled until
/// [selectedCounty] is set. There is no back button, since this is the
/// first step (the shell hides it when [OnboardingShell.onBack] is null).
class OnboardingHomeCountyPage extends StatelessWidget {
  const OnboardingHomeCountyPage({
    super.key,
    required this.selectedCounty,
    required this.isSaving,
    required this.errorMessage,
    required this.onSelected,
    required this.onContinue,
  });

  final CountyPath? selectedCounty;
  final bool isSaving;
  final String? errorMessage;
  final ValueChanged<CountyPath> onSelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      step: 1,
      pill: 'Earn all 47 counties',
      title: 'Where is home?',
      subtitle: const Text(
        "Spend about two hours in a county and it's yours. Your map and "
        'suggestions start from home.',
      ),
      primaryLabel: 'Continue',
      onPrimary: selectedCounty == null ? null : onContinue,
      footerCaption: 'Change it later in Settings',
      isBusy: isSaving,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.pageBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 64, 12, 80),
                  child: AppCountyMap(
                    selectedCounty: selectedCounty,
                    onCountySelected: onSelected,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _SearchBar(onPressed: () => _openSearchSheet(context)),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _SelectedCountyCard(
                county: selectedCounty,
                errorMessage: errorMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSearchSheet(BuildContext context) async {
    final county = await CountyPickerSheet.show(
      context,
      selectedCounty: selectedCounty,
    );
    if (county != null) {
      onSelected(county);
    }
  }
}

/// Always on screen, so searching never needs hunting for an icon.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Search 47 counties',
      excludeSemantics: true,
      onTap: onPressed,
      child: Material(
        color: Colors.white,
        elevation: 3,
        shadowColor: AppColors.detailGlassShadow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Search 47 counties',
                    style: AppTextStyles.searchInputText.copyWith(
                      color: AppColors.mutedForeground,
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

/// The pick, as a card: the county's badge, its name, and a hint to tap
/// another. Before a pick it says how to start.
/// A save error replaces the hint line.
class _SelectedCountyCard extends StatelessWidget {
  const _SelectedCountyCard({
    required this.county,
    required this.errorMessage,
  });

  final CountyPath? county;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final picked = county;
    final hint = errorMessage ?? 'Tap another county to change';
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: AppColors.detailGlassShadow,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // The county's own badge, as it will look once earned.
            if (picked == null)
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.pageBackground,
                ),
                child: const Icon(
                  Icons.touch_app_outlined,
                  size: 18,
                  color: AppColors.mutedForeground,
                ),
              )
            else
              CountyBadgeMedallion(county: picked, earned: true, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    picked?.name ?? 'Tap your county on the map',
                    style: AppTextStyles.listItemTitle.copyWith(fontSize: 14),
                  ),
                  if (picked != null || errorMessage != null)
                    Text(
                      hint,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11.5,
                        color: errorMessage == null
                            ? AppColors.mutedForeground
                            : AppColors.danger,
                      ),
                    ),
                ],
              ),
            ),
            if (picked != null)
              const Icon(
                Icons.check_circle_outline,
                size: 20,
                color: AppColors.legendHome,
              ),
          ],
        ),
      ),
    );
  }
}
