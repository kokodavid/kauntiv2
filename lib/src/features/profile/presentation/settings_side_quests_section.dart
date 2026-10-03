import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/profile_settings.dart';
import 'settings_privacy_section.dart' show ProfileSettingsControllerRef;
import 'settings_widgets.dart';

class SettingsSideQuestsSection extends StatelessWidget {
  const SettingsSideQuestsSection({
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
      const SettingsSectionLabel(
        'Side quests',
        trailing: Text(
          'Coming soon',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
      ),
      SettingsCard(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suggest places within',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Of where you are when the feed opens',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 10),
                SettingsSegmented<int>(
                  options: ProfileSettings.radiusChoicesKm,
                  labelOf: (v) => '$v km',
                  value: settings.sideQuestRadiusKm,
                  onChanged: (v) => unawaited(notifier.setSideQuestRadiusKm(v)),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}
