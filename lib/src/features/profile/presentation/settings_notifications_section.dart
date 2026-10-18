import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../notifications/application/notification_permission_provider.dart';
import '../domain/profile_settings.dart';
import 'settings_privacy_section.dart' show ProfileSettingsControllerRef;
import 'settings_weekend_section.dart';
import 'settings_widgets.dart';

class SettingsNotificationsSection extends ConsumerWidget {
  const SettingsNotificationsSection({
    super.key,
    required this.settings,
    required this.notifier,
    this.onOpenPhoneSettings,
  });

  final ProfileSettings settings;
  final ProfileSettingsControllerRef notifier;

  /// Opens the phone's settings for this app (offered when notifications
  /// are off at the OS level).
  final VoidCallback? onOpenPhoneSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(notificationsBlockedProvider).value ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionLabel('Notifications'),
        if (blocked && onOpenPhoneSettings != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: onOpenPhoneSettings,
              child: const Text(
                'Notifications are off for Kaunti47 on this phone. '
                'Tap to open phone settings.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        SettingsCard(
          children: [
            SettingsToggleRow(
              title: 'Badge unlocks',
              subtitle: 'When you earn a new county',
              value: settings.notifyBadgeUnlocks,
              onChanged: (v) => unawaited(notifier.setNotifyBadgeUnlocks(v)),
            ),
            SettingsToggleRow(
              title: 'County nudges',
              subtitle: "When you're near a county you haven't claimed",
              value: settings.notifyCountyNudges,
              onChanged: (v) => unawaited(notifier.setNotifyCountyNudges(v)),
              divider: true,
            ),
            SettingsToggleRow(
              title: 'Photo reviews',
              subtitle: 'When a photo you sent has been reviewed',
              value: settings.notifyPhotoReviews,
              onChanged: (v) => unawaited(notifier.setNotifyPhotoReviews(v)),
              divider: true,
            ),
            SettingsToggleRow(
              title: 'Trip reminders',
              subtitle: 'When a trip you are recording stays paused',
              value: settings.notifyTripAlerts,
              onChanged: (v) => unawaited(notifier.setNotifyTripAlerts(v)),
              divider: true,
            ),
            SettingsToggleRow(
              title: 'Weekend ideas',
              subtitle:
                  'A saved plan or place worth a trip, Thursday afternoons',
              value: settings.notifyWeekendPlans,
              onChanged: (v) => unawaited(notifier.setNotifyWeekendPlans(v)),
              divider: true,
            ),
            SettingsToggleRow(
              title: 'Announcements',
              subtitle: 'News about Kaunti47: new features and regions',
              value: settings.notifyAnnouncements,
              onChanged: (v) => unawaited(notifier.setNotifyAnnouncements(v)),
              divider: true,
            ),
          ],
        ),
        if (settings.notifyWeekendPlans) ...[
          const SizedBox(height: 12),
          SettingsWeekendSection(settings: settings, notifier: notifier),
        ],
      ],
    );
  }
}
