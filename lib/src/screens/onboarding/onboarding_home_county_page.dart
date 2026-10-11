import 'package:flutter/material.dart';

import '../../counties/county_paths.dart';
import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../widgets/app_county_map.dart';
import '../../widgets/county_picker_sheet.dart';
import 'onboarding_shell.dart';

/// Setup step 1 of 3: pick your home county (Figma "Karibu" node
/// 235:4745, search sheet at node 235:6967), inside the shared
/// [OnboardingShell]. Tapping a county's shape on the map selects it, and
/// a small search button over the map opens [CountyPickerSheet].
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
      title: 'Where is home?',
      subtitle: const Text(
        'Suggestions start here. You can change it later in Settings.',
      ),
      primaryLabel: 'Continue',
      onPrimary: selectedCounty == null ? null : onContinue,
      isBusy: isSaving,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: AppCountyMap(
                      selectedCounty: selectedCounty,
                      onCountySelected: onSelected,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 4,
                    child: _SearchIconButton(
                      onPressed: () => _openSearchSheet(context),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: _MapCaptionChip(selectedCounty: selectedCounty),
                  ),
                ],
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: AppTextStyles.listItemSubtitle.copyWith(
                  color: AppColors.headingText,
                ),
              ),
            ],
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

class _SearchIconButton extends StatelessWidget {
  const _SearchIconButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.iconButtonBackground,
          side: BorderSide.none,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: const Icon(Icons.search, size: 16, color: AppColors.foreground),
      ),
    );
  }
}

/// Instruction chip over the map's bottom edge. Doubles as the
/// selected-county label once a county is picked -- Figma's own caption
/// ("Tap your county on the map") only ever shows the instruction, but
/// with no other on-screen confirmation of *which* county got tapped
/// (the map's fill change is easy to miss on a shape this small), naming
/// it here reuses the one piece of chrome already anchored to the map
/// instead of adding new UI for it.
class _MapCaptionChip extends StatelessWidget {
  const _MapCaptionChip({required this.selectedCounty});

  final CountyPath? selectedCounty;

  @override
  Widget build(BuildContext context) {
    final county = selectedCounty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondaryFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        county == null ? 'Tap your county on the map' : county.name,
        style: AppTextStyles.chipLabel,
      ),
    );
  }
}
