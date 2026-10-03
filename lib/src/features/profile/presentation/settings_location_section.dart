import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/profile_settings.dart';
import 'settings_privacy_section.dart' show ProfileSettingsControllerRef;
import 'settings_widgets.dart';

class SettingsLocationSection extends StatelessWidget {
  const SettingsLocationSection({
    super.key,
    required this.settings,
    required this.notifier,
    required this.onOpenLocationSettings,
  });

  final ProfileSettings settings;
  final ProfileSettingsControllerRef notifier;
  final VoidCallback onOpenLocationSettings;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SettingsSectionLabel('Location'),
      SettingsCard(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'County detection',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Counties are claimed in the background as you travel.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF71717A)),
                ),
                const SizedBox(height: 10),
                SettingsSegmented<LocationMode>(
                  options: LocationMode.values,
                  labelOf: (v) => v == LocationMode.automatic ? 'Automatic' : 'Manual',
                  value: settings.locationMode,
                  onChanged: (v) => unawaited(notifier.setLocationMode(v)),
                ),
              ],
            ),
          ),
          SettingsActionRow(
            title: 'Location permission',
            subtitle: 'Opens device settings',
            onTap: onOpenLocationSettings,
            trailing: const Icon(Icons.open_in_new, size: 18),
            divider: true,
          ),
        ],
      ),
    ],
  );
}
