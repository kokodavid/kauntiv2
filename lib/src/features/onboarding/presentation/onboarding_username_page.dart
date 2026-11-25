import 'package:flutter/material.dart';

import 'onboarding_shell.dart';

/// Setup step 3 of 4: pick the name other explorers see. The field holds the
/// generated name and four suggestions sit below it, so Continue is one tap
/// and typing your own is there for anyone with a name in mind. "Skip for
/// now" leaves the generated name unconfirmed.
class OnboardingUsernamePage extends StatelessWidget {
  const OnboardingUsernamePage({
    super.key,
    required this.picker,
    required this.canContinue,
    required this.isSaving,
    required this.onContinue,
    required this.onSkip,
    required this.onBack,
  });

  /// The shared picker, already bound to the chooser's state.
  final Widget picker;
  final bool canContinue;
  final bool isSaving;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      step: 3,
      title: 'Pick your explorer name',
      subtitle: const Text(
        'This is the name other explorers see on your photos and shared '
        'trips. Your real name is never shown.',
      ),
      onBack: onBack,
      primaryLabel: 'Continue',
      onPrimary: canContinue ? onContinue : null,
      secondaryLabel: 'Skip for now',
      onSecondary: onSkip,
      isBusy: isSaving,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: picker,
      ),
    );
  }
}
