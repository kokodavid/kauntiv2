import 'package:flutter/material.dart';

import 'onboarding_permission_parts.dart';
import 'onboarding_shell.dart';

/// The last part of setup step 3, shown once location is on: our own ask
/// before the phone's. "Not now" leaves the one-time OS prompt unused, so
/// it can still be asked later; the system prompt only appears after
/// "Turn on notifications".
class OnboardingNotificationsPage extends StatelessWidget {
  const OnboardingNotificationsPage({
    super.key,
    required this.isRequesting,
    required this.onEnable,
    required this.onNotNow,
  });

  final bool isRequesting;
  final VoidCallback onEnable;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      step: 3,
      title: 'Know when you cross a line',
      subtitle: const Text(
        'Get a quick heads-up the moment you enter a new county, even '
        'when the app is closed.',
      ),
      primaryLabel: 'Turn on notifications',
      onPrimary: onEnable,
      secondaryLabel: 'Not now',
      onSecondary: onNotNow,
      isBusy: isRequesting,
      child: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          children: [
            PermissionFact(
              icon: Icons.notifications_none_outlined,
              title: 'Only for new counties.',
              body: 'At most one per county a week. Never your home county.',
            ),
            SizedBox(height: 14),
            PermissionFact(
              icon: Icons.touch_app_outlined,
              title: 'One tap:',
              body: 'opens what to see and do in the county you just entered.',
            ),
            SizedBox(height: 14),
            PermissionFact(
              icon: Icons.lock_outline,
              title: 'Stays on your phone.',
              body: 'The alert is made on your device. No location is sent.',
            ),
            SizedBox(height: 14),
            PermissionFact(
              icon: Icons.tune_outlined,
              title: "You're in control:",
              body: 'turn it off any time in Settings.',
            ),
          ],
        ),
      ),
    );
  }
}
