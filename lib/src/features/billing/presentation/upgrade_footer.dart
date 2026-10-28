import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/app_external_links.dart';
import '../../../design/app_colors.dart';

/// The disclosures the stores require on a subscription screen, plus the
/// restore, terms and privacy links.
class UpgradeFooter extends StatelessWidget {
  const UpgradeFooter({
    super.key,
    required this.onRestore,
    required this.restoreEnabled,
  });

  final VoidCallback onRestore;
  final bool restoreEnabled;

  @override
  Widget build(BuildContext context) {
    final store = AppExternalLinks.subscriptionStoreName;
    const muted = TextStyle(fontSize: 12, color: AppColors.mutedForeground);
    return Column(
      children: [
        TextButton(
          onPressed: restoreEnabled ? onRestore : null,
          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          child: const Text('Restore purchases'),
        ),
        Text(
          'Your subscription renews automatically each period until you '
          'cancel it. Cancel any time in your $store subscription settings, '
          'at least 24 hours before it renews. Payment is charged to your '
          '$store account when you confirm the purchase.',
          textAlign: TextAlign.center,
          style: muted,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => unawaited(AppExternalLinks.openTerms()),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mutedForeground,
              ),
              child: const Text('Terms'),
            ),
            TextButton(
              onPressed: () => unawaited(AppExternalLinks.openPrivacyPolicy()),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mutedForeground,
              ),
              child: const Text('Privacy'),
            ),
          ],
        ),
      ],
    );
  }
}
