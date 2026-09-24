import 'package:flutter/material.dart';

import '../../counties/county_paths.dart';
import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../widgets/app_county_map.dart';
import '../../widgets/county_picker_sheet.dart';

/// v2 home-county picker (Figma "Karibu" node 235:4745, with the search
/// sheet at node 235:6967). Full rewrite of the v1 screen, matching the
/// pattern already used for the splash and Onboarding 02 rebuilds: same
/// constructor/callbacks as before so `OnboardingFlow`'s wiring is
/// untouched, new visuals and interaction inside.
///
/// Two real interaction changes from v1, not just a restyle:
/// - Tapping a county's actual shape on the map now selects it directly
///   (`AppCountyMap.onCountySelected`, new hit-testing) -- v1's map tap
///   only ever opened the picker sheet.
/// - Search moved off the screen itself and into a dedicated bottom
///   sheet (`CountyPickerSheet`, reusable) opened by a small search
///   button over the map, rather than an always-visible search bar with
///   an inline results dropdown.
///
/// Selecting a home county is mandatory -- there is no skip option (a
/// "Skip - suggest one from my first location" button existed here
/// briefly, matching an earlier Figma pass, but nothing behind it
/// actually inferred a county from the first detected location, and the
/// step is cheap enough for the user to just answer). `Continue` stays
/// disabled until [selectedCounty] is set.
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
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // No AppBackButton here -- this screen sits inside
              // OnboardingFlow's linear PageView with no back route to
              // go to. See AppBackButton's doc comment.
              const Text(
                'Which county do you call home?',
                style: AppTextStyles.headingForeground,
              ),
              const SizedBox(height: 8),
              const Text(
                'Where you are from, not where life happens to have you. '
                'you can change it anytime.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              _PrimaryPillButton(
                label: isSaving ? 'Saving...' : 'Continue',
                onPressed: isSaving || selectedCounty == null
                    ? null
                    : onContinue,
                isBusy: isSaving,
              ),
            ],
          ),
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

class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({
    required this.label,
    required this.onPressed,
    required this.isBusy,
  });

  final String label;
  final VoidCallback? onPressed;

  /// True while `isSaving` -- that's a disabled-but-active state (the
  /// request is in flight) and should still read as solid/accent, not
  /// inert. Only a *genuinely* inactive disabled state -- nothing
  /// selected yet, before the skip option existed this screen always
  /// had something to save -- should look visually turned off, so a
  /// user doesn't tap a seemingly-live button and get nothing.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final showsInactive = onPressed == null && !isBusy;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          disabledBackgroundColor: isBusy
              ? AppColors.accent
              : AppColors.secondaryFill,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          label,
          style: showsInactive
              ? AppTextStyles.buttonLabel.copyWith(
                  color: AppColors.mutedForeground,
                )
              : AppTextStyles.buttonLabel,
        ),
      ),
    );
  }
}
