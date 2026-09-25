import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import 'journey_recording_controls.dart';
import 'journey_recording_screen.dart';
import 'journey_start_card.dart';

/// The Journey in progress on the Journeys tab: its controls and a way
/// back to the full-screen map (where recording normally happens).
class JourneyLiveCard extends StatelessWidget {
  const JourneyLiveCard({super.key, this.onOpenSettings, this.onOpenMap});

  final OpenAppSettings? onOpenSettings;
  final OpenJourneyRecording? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final open = onOpenMap;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JourneyRecordingControls(onOpenSettings: onOpenSettings),
          if (open != null) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => open(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open map'),
            ),
          ],
        ],
      ),
    );
  }
}
