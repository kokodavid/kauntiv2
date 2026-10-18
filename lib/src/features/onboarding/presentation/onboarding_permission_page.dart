import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../profile/domain/place_interest.dart';
import 'onboarding_permission_ask.dart';
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
    required this.isDeviceAsk,
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

  /// A returning user on a new phone: not setup step 3, so no "3 of 3" and
  /// nothing to go back to.
  final bool isDeviceAsk;
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
        : ('Let counties unlock on their own', _askLine());
    return OnboardingShell(
      step: isDeviceAsk ? null : 3,
      title: title,
      subtitle: subtitle,
      onBack: isDeviceAsk ? null : onBack,
      primaryLabel: isPermanentlyDenied
          ? 'Open Settings'
          : (_denied ? 'Try again' : 'Enable location'),
      onPrimary: onEnableLocation,
      footerNote: isPermanentlyDenied || _denied
          ? null
          : const PermissionPromptNote(),
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
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
                color: Colors.white,
              ),
            ),
            const TextSpan(text: ' near you, and '),
          ],
          const TextSpan(text: 'notice each county line you cross.'),
        ],
      ),
    );
  }
}

class _AskBody extends StatelessWidget {
  const _AskBody();

  static const _items = [
    (
      Icons.location_on_outlined,
      'Wakes only at lines',
      'No constant GPS. Almost no battery.',
    ),
    (
      Icons.shield_outlined,
      'Entries, never traces',
      '"Entered Turkana on Saturday". Nothing more.',
    ),
    (
      Icons.cloud_outlined,
      'Works offline',
      'Badges confirm once you have signal.',
    ),
    (
      Icons.tune_outlined,
      "You're in control",
      'Manual mode or delete history in Profile.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PermissionHowEarned(),
        const SizedBox(height: 10),
        for (var row = 0; row < _items.length; row += 2) ...[
          if (row > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = row; i < row + 2; i++) ...[
                  if (i > row) const SizedBox(width: 10),
                  Expanded(
                    child: PermissionReassurance(
                      icon: _items[i].$1,
                      title: _items[i].$2,
                      body: _items[i].$3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
