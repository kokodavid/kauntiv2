import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../features/profile/domain/place_interest.dart';
import 'onboarding_permission_parts.dart';
import 'onboarding_shell.dart';

/// Setup step 3 of 3: background location, inside the shared
/// [OnboardingShell]. Three states share the same footer slots:
///
/// - **Default:** why we ask, tied to what the user picked on step 2.
/// - **Denied:** one retry, and "Continue without location" to Home.
/// - **Permanently denied:** three taps to turn it on in Settings.
///
/// "Not now" is always available and always reaches Home. While the OS
/// prompt is up ([isRequesting]) the footer locks, so a double tap can't
/// skip the step.
class OnboardingPermissionPage extends StatelessWidget {
  const OnboardingPermissionPage({
    super.key,
    required this.isRequesting,
    required this.isPermanentlyDenied,
    required this.errorMessage,
    required this.interests,
    required this.showSkipToast,
    required this.onEnableLocation,
    required this.onNotNow,
    required this.onBack,
    required this.onUndoSkip,
  });

  final bool isRequesting;
  final bool isPermanentlyDenied;

  /// Set after the OS said no without it being permanent.
  final String? errorMessage;
  final List<PlaceInterest> interests;

  /// Right after "Skip for now" on step 2: show the Undo toast.
  final bool showSkipToast;
  final VoidCallback onEnableLocation;
  final VoidCallback onNotNow;
  final VoidCallback onBack;
  final VoidCallback onUndoSkip;

  bool get _denied => errorMessage != null && !isPermanentlyDenied;

  /// "waterfalls and coast", from the first two picks; null after a skip.
  String? get _tieIn {
    if (interests.isEmpty) return null;
    final names = [for (final i in interests.take(2)) i.shortName];
    return names.join(' and ');
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = isPermanentlyDenied
        ? (
            'Turn on location in Settings',
            const Text("Your phone won't ask again. It takes three taps."),
          )
        : _denied
        ? (
            'Location is off',
            const Text(
              "Without it, counties won't unlock on their own. "
              'You can turn it on later in Settings.',
            ),
          )
        : ('One last thing', _askLine());
    return OnboardingShell(
      step: 3,
      title: title,
      subtitle: subtitle,
      onBack: onBack,
      primaryLabel: isPermanentlyDenied
          ? 'Open Settings'
          : (_denied ? 'Try again' : 'Enable location'),
      onPrimary: onEnableLocation,
      secondaryLabel: _denied ? 'Continue without location' : 'Not now',
      onSecondary: onNotNow,
      isBusy: isRequesting,
      overlay: showSkipToast
          ? Positioned(
              left: 16,
              right: 16,
              bottom: 140,
              child: OnboardingUndoToast(
                message: 'Skipped. Add interests anytime in Settings.',
                onUndo: onUndoSkip,
              ),
            )
          : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: isPermanentlyDenied
            ? const _PermanentlyDeniedBody()
            : _denied
            ? _DeniedBody(message: errorMessage!)
            : const _AskBody(),
      ),
    );
  }

  Widget _askLine() {
    final tie = _tieIn;
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Allow location so we can '),
          if (tie != null) ...[
            const TextSpan(text: 'find '),
            TextSpan(
              text: tie,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            const TextSpan(text: ' near you, and '),
          ],
          const TextSpan(text: 'unlock counties as you cross into them.'),
        ],
      ),
    );
  }
}

class _AskBody extends StatelessWidget {
  const _AskBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PermissionFact(
          icon: Icons.location_on_outlined,
          title: 'Wakes only at boundaries.',
          body:
              "Your phone's own geofencing nudges the app at county lines. "
              'No constant GPS, almost no battery.',
        ),
        SizedBox(height: 14),
        PermissionFact(
          icon: Icons.shield_outlined,
          title: 'County entries, never traces.',
          body:
              'We store "entered Turkana on Saturday", not where you went or '
              'slept.',
        ),
        SizedBox(height: 14),
        PermissionFact(
          icon: Icons.cloud_outlined,
          title: 'Works offline.',
          body:
              'No bars in Marsabit? The badge lands on your phone and '
              'confirms when you are back in coverage.',
        ),
        SizedBox(height: 14),
        PermissionFact(
          icon: Icons.tune_outlined,
          title: "You're in control.",
          body:
              'Switch to manual mode or delete your history anytime from '
              'Profile → Location mode.',
        ),
        SizedBox(height: 14),
        PermissionPromptNote(),
      ],
    );
  }
}

class _DeniedBody extends StatelessWidget {
  const _DeniedBody({required this.message});

  /// Why the phone said no (denied, restricted or a failed request).
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: AppTextStyles.bodySmall),
        const SizedBox(height: 14),
        const PermissionFact(
          icon: Icons.location_on_outlined,
          title: 'With location:',
          body: 'badges land as you cross county lines.',
        ),
        const SizedBox(height: 14),
        const PermissionFact(
          icon: Icons.tune_outlined,
          title: 'Without it:',
          body: 'you can turn location on any time in Settings.',
          tint: AppColors.mutedForeground,
        ),
      ],
    );
  }
}

class _PermanentlyDeniedBody extends StatelessWidget {
  const _PermanentlyDeniedBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PermissionSettingsSteps(),
        const SizedBox(height: 12),
        Text(
          'When you come back with location on, we take you straight to Home.',
          style: AppTextStyles.bodySmall.copyWith(fontSize: 12.5),
        ),
      ],
    );
  }
}
