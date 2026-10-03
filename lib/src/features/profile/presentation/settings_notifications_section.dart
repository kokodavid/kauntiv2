import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/profile_settings.dart';
import 'settings_privacy_section.dart' show ProfileSettingsControllerRef;
import 'settings_widgets.dart';

class SettingsNotificationsSection extends StatelessWidget {
  const SettingsNotificationsSection({
    super.key,
    required this.settings,
    required this.notifier,
  });

  final ProfileSettings settings;
  final ProfileSettingsControllerRef notifier;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SettingsSectionLabel('Notifications'),
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
        ],
      ),
    ],
  );
}
