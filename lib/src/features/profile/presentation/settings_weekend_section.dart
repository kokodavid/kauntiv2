import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/profile_settings.dart';
import 'settings_privacy_section.dart' show ProfileSettingsControllerRef;
import 'settings_widgets.dart';

/// How "Weekend ideas" picks what to suggest: things the user saved first,
/// then (optionally) places near their home county that match their
/// interests. Shown under the Notifications card while Weekend ideas is on.
class SettingsWeekendSection extends StatelessWidget {
  const SettingsWeekendSection({
    super.key,
    required this.settings,
    required this.notifier,
  });

  final ProfileSettings settings;
  final ProfileSettingsControllerRef notifier;

  @override
  Widget build(BuildContext context) => SettingsCard(
    children: [
      SettingsToggleRow(
        title: 'Places and plans I saved',
        subtitle: 'Suggest from your saved plans and wishlist first',
        value: settings.weekendUseSaved,
        onChanged: (v) => unawaited(notifier.setWeekendUseSaved(v)),
      ),
      SettingsToggleRow(
        title: 'Ideas near me',
        subtitle: 'When you have nothing saved, suggest places that match '
            'your interests',
        value: settings.weekendIncludeNearby,
        onChanged: (v) => unawaited(notifier.setWeekendIncludeNearby(v)),
        divider: true,
      ),
      if (settings.weekendIncludeNearby)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Within',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              const Text(
                'Of the centre of your home county',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 10),
              SettingsSegmented<int>(
                options: ProfileSettings.weekendRadiusChoicesKm,
                labelOf: (v) => '$v km',
                value: settings.weekendRadiusKm,
                onChanged: (v) => unawaited(notifier.setWeekendRadiusKm(v)),
              ),
            ],
          ),
        ),
    ],
  );
}
