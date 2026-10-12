import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_external_links.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

/// The line under the sign-in buttons: continuing means accepting the
/// privacy policy, which opens kaunti47.com/privacy in the browser.
class OnboardingPrivacyNote extends StatefulWidget {
  const OnboardingPrivacyNote({super.key, this.onOpen});

  /// Opens the policy; defaults to the browser. Tests override it.
  final Future<void> Function()? onOpen;

  @override
  State<OnboardingPrivacyNote> createState() => _OnboardingPrivacyNoteState();
}

class _OnboardingPrivacyNoteState extends State<OnboardingPrivacyNote> {
  late final TapGestureRecognizer _tap = TapGestureRecognizer()
    ..onTap = () => unawaited(_open());

  Future<void> _open() async {
    try {
      await (widget.onOpen ?? AppExternalLinks.openPrivacyPolicy)();
    } on Object {
      // Best effort external link; no in-app fallback.
    }
  }

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.bodySmall.copyWith(
      color: AppColors.mutedForeground,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            const TextSpan(text: 'By continuing you accept our '),
            TextSpan(
              text: 'Privacy Policy',
              recognizer: _tap,
              style: base.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
