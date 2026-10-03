import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/profile_settings.dart';
import 'settings_widgets.dart';

class SettingsPrivacySection extends ConsumerWidget {
  const SettingsPrivacySection({super.key, required this.settings, required this.notifier});

  final ProfileSettings settings;
  final ProfileSettingsControllerRef notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SettingsSectionLabel('Privacy'),
      SettingsCard(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Who can see your county map',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Friends see your claimed counties. Routes are never shared.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF71717A)),
                ),
                const SizedBox(height: 10),
                SettingsSegmented<MapVisibility>(
                  options: MapVisibility.values,
                  labelOf: (v) => v.label,
                  value: settings.mapVisibility,
                  onChanged: (v) => unawaited(notifier.setMapVisibility(v)),
                ),
              ],
            ),
          ),
          SettingsToggleRow(
            title: 'Show me on leaderboards',
            subtitle: 'Uses your name, handle and photo',
            value: settings.showOnLeaderboards,
            onChanged: (v) => unawaited(notifier.setShowOnLeaderboards(v)),
            divider: true,
          ),
        ],
      ),
    ],
  );
}

/// The subset of [ProfileSettingsController] the sections call -- a
/// typedef so each section doesn't need its own `WidgetRef` plumbing.
typedef ProfileSettingsControllerRef = ({
  Future<void> Function(MapVisibility) setMapVisibility,
  Future<void> Function(bool) setShowOnLeaderboards,
  Future<void> Function(bool) setNotifyBadgeUnlocks,
  Future<void> Function(bool) setNotifyCountyNudges,
  Future<void> Function(int) setSideQuestRadiusKm,
  Future<void> Function(LocationMode) setLocationMode,
});
