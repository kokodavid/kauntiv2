import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/app_external_links.dart';
import '../../../design/app_colors.dart';

/// In-app summary of the data this build actually keeps, with a link to the
/// full published privacy policy (kaunti47.com/privacy).
class ProfilePrivacySheet extends StatelessWidget {
  const ProfilePrivacySheet({super.key});

  Future<void> _openPolicy() async {
    try {
      await AppExternalLinks.openPrivacyPolicy();
    } on Object {
      // Best effort external link; no in-app fallback.
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data and privacy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            const Text(
              'County visits and earned badges are saved to your account so '
              'they can follow you between devices.',
            ),
            const SizedBox(height: 12),
            const Text(
              'If you pick interests, such as waterfalls or coast, that short '
              'list is saved to your account. We use it only to put places '
              "you'd like higher in For you. Change or clear it any time in "
              'Settings > Interests; it is deleted with your account.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Trips record your route. Completed Trips are kept on '
              'this phone and synced privately to your account when '
              'available. You can delete a Trip from its list.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Location permission can be changed at any time in your device '
              'settings. Turning it off stops new automatic county detection '
              'and Trip recording.',
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => unawaited(_openPolicy()),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Read the full privacy policy'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Done',
                  style: TextStyle(color: AppColors.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
