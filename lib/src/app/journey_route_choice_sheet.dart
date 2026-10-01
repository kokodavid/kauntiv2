import 'package:flutter/material.dart';

import '../design/app_colors.dart';

enum JourneyRouteChoice { record, directions }

/// Route actions sit above the shell's floating bottom navigation.
abstract final class JourneyRouteChoiceSheet {
  static Future<JourneyRouteChoice?> show(
    BuildContext context,
    String placeName,
  ) => showModalBottomSheet<JourneyRouteChoice>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Go to $placeName',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(
                    sheetContext,
                  ).pop(JourneyRouteChoice.directions),
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text('Directions only'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentForeground,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(JourneyRouteChoice.record),
                  icon: const Icon(Icons.route_rounded),
                  label: const Text('Record as a Trip'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your route is saved privately. Stop recording when you finish.',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
