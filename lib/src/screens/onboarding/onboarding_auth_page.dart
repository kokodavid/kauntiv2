import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../widgets/app_icon_badge.dart';
import '../../widgets/app_progress_indicator.dart';
import 'onboarding_common.dart';

/// v2 combined pitch + sign-in screen (Figma node 423:3052,
/// "Onboarding"). Replaces the v1 green full-bleed auth design.
/// The onboarding flow is splash -> this screen -> home county -> location
/// permission; the old 3-slide intro carousel ("how it works") has been
/// removed from the app entirely, not just unrouted.
class OnboardingAuthPage extends StatelessWidget {
  const OnboardingAuthPage({
    super.key,
    required this.onGoogle,
    required this.onApple,
    required this.showApple,
    this.isGoogleLoading = false,
    this.isAppleLoading = false,
    required this.errorMessage,
  });

  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final bool showApple;

  /// Shows a spinner on the Google button and disables both buttons while
  /// the Google sign-in call is in flight.
  final bool isGoogleLoading;

  /// Shows a spinner on the Apple button and disables both buttons while
  /// the Apple sign-in call is in flight.
  final bool isAppleLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIconBadge(size: 60),
                  SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Lots of Love for', style: AppTextStyles.kickerText),
                      SizedBox(width: 8),
                      _KenyaPill(),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Begin your journey. Fill in the map of Kenya.',
                    style: AppTextStyles.heading,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SvgPicture.asset(
                'assets/images/onboarding.svg',
                key: const Key('onboarding-illustration'),
                width: double.infinity,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                placeholderBuilder: (context) => const Center(
                  child: AppProgressIndicator(
                    color: AppColors.mutedForeground,
                    radius: 10,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  if (errorMessage != null) ...[
                    Text(
                      errorMessage!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.headingText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                  OnboardingAuthButton(
                    label: 'Continue with Google',
                    useGoogleLogo: true,
                    isLoading: isGoogleLoading,
                    onPressed: isAppleLoading ? null : onGoogle,
                  ),
                  if (showApple) ...[
                    const SizedBox(height: 12),
                    OnboardingAuthButton(
                      label: 'Continue with Apple',
                      icon: Icons.apple,
                      isLoading: isAppleLoading,
                      onPressed: isGoogleLoading ? null : onApple,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KenyaPill extends StatelessWidget {
  const _KenyaPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.kenyaPillBackground,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(-2, 4),
            blurRadius: 2.65,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Placeholder for the Figma frame's flag glyph -- a flag emoji
          // rather than a new vector asset, since Kenya's flag isn't
          // otherwise used anywhere in the app yet.
          Text('\u{1F1F0}\u{1F1EA}', style: TextStyle(fontSize: 12)),
          SizedBox(width: 4),
          Text(
            'Kenya',
            style: TextStyle(
              fontSize: 12,
              height: 20 / 12,
              color: Color(0xFFF3F4F6),
            ),
          ),
        ],
      ),
    );
  }
}
