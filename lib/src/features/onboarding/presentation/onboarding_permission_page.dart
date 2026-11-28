import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/location_choice.dart';
import 'onboarding_permission_ask.dart';
import 'onboarding_permission_choice.dart';
import 'onboarding_permission_parts.dart';
import 'onboarding_shell.dart';

/// Setup step 4 of 4: location, inside the shared
/// [OnboardingShell]. Three states share the same footer slots:
///
/// - **Default:** the earned-county strip and the two choices ("All the
///   time" or "Only while using"), then the phone's own prompt.
/// - **Denied:** one retry, and "Continue without location" to Home.
/// - **Permanently denied:** three taps to turn it on in Settings.
///
/// There is no way off this page until the OS prompt has been answered:
/// App Store guideline 5.1.1(iv) requires that a custom message shown
/// before a permission request always leads to the request itself. The way
/// out ("Continue without location", or "Not now" once the phone won't ask
/// again) only appears after the phone has had its say. While the OS prompt
/// is up ([isRequesting]) the footer locks, so a double tap can't skip the
/// step.
class OnboardingPermissionPage extends StatefulWidget {
  const OnboardingPermissionPage({
    super.key,
    required this.isRequesting,
    required this.isDeviceAsk,
    required this.isPermanentlyDenied,
    required this.errorMessage,
    required this.showSkipToast,
    required this.onEnableLocation,
    required this.onNotNow,
    required this.onBack,
    required this.onUndoSkip,
  });

  final bool isRequesting;

  /// A returning user on a new phone: not setup step 4, so no "4 of 4" and
  /// nothing to go back to.
  final bool isDeviceAsk;
  final bool isPermanentlyDenied;

  /// Set after the OS said no without it being permanent.
  final String? errorMessage;

  /// Right after "Skip for now" on step 2: show the Undo toast.
  final bool showSkipToast;
  final ValueChanged<LocationChoice> onEnableLocation;
  final VoidCallback onNotNow;
  final VoidCallback onBack;
  final VoidCallback onUndoSkip;

  @override
  State<OnboardingPermissionPage> createState() =>
      _OnboardingPermissionPageState();
}

class _OnboardingPermissionPageState extends State<OnboardingPermissionPage> {
  LocationChoice _choice = LocationChoice.allTheTime;

  bool get _denied =>
      widget.errorMessage != null && !widget.isPermanentlyDenied;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = widget.isPermanentlyDenied
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
        : (
            'Let counties unlock on their own',
            const Text(
              'Choose how Kaunti47 notices each county line you cross.',
            ),
          );
    return OnboardingShell(
      step: widget.isDeviceAsk ? null : 4,
      title: title,
      subtitle: subtitle,
      onBack: widget.isDeviceAsk ? null : widget.onBack,
      primaryLabel: widget.isPermanentlyDenied
          ? 'Open Settings'
          : (_denied
                ? 'Try again'
                : (_choice == LocationChoice.allTheTime
                      ? 'Allow all the time'
                      : 'Allow while using')),
      onPrimary: () => widget.onEnableLocation(_choice),
      footerNote: widget.isPermanentlyDenied || _denied
          ? null
          : PermissionPromptNote(choice: _choice),
      // No way past the ask until the phone has been asked (5.1.1(iv)).
      secondaryLabel: widget.isPermanentlyDenied
          ? 'Not now'
          : (_denied ? 'Continue without location' : null),
      onSecondary: widget.isPermanentlyDenied || _denied
          ? widget.onNotNow
          : null,
      isBusy: widget.isRequesting,
      overlay: widget.showSkipToast
          ? Positioned(
              left: 16,
              right: 16,
              bottom: 140,
              child: OnboardingUndoToast(
                message: 'Skipped. Add interests anytime in Settings.',
                onUndo: widget.onUndoSkip,
              ),
            )
          : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: widget.isPermanentlyDenied
            ? const _PermanentlyDeniedBody()
            : _denied
            ? _DeniedBody(message: widget.errorMessage!)
            : _AskBody(
                choice: _choice,
                onChanged: (c) => setState(() => _choice = c),
              ),
      ),
    );
  }
}

class _AskBody extends StatelessWidget {
  const _AskBody({required this.choice, required this.onChanged});

  final LocationChoice choice;
  final ValueChanged<LocationChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PermissionHowEarned(),
        const SizedBox(height: 10),
        PermissionChoiceCards(choice: choice, onChanged: onChanged),
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
