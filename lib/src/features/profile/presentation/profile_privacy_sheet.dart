import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';

/// In-app summary of the data this build actually keeps. This is not a
/// substitute for the published privacy policy required for release.
class ProfilePrivacySheet extends StatelessWidget {
  const ProfilePrivacySheet({super.key});

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
            const SizedBox(height: 20),
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
