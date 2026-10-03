import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/journey_transport_mode.dart';

/// The icon a transport mode shows everywhere it appears - the picker
/// sheet below and a Trip's card/tile - so they always agree.
IconData journeyTransportModeIcon(JourneyTransportMode mode) => switch (mode) {
  JourneyTransportMode.drive => Icons.directions_car_filled_rounded,
  JourneyTransportMode.walk => Icons.directions_walk_rounded,
  JourneyTransportMode.cycle => Icons.directions_bike_rounded,
};

/// A mandatory bottom sheet asking how a Trip is being travelled before
/// recording starts. There is no default: dismissing it without picking
/// returns null, and the caller is expected not to start recording in
/// that case, so every Trip that does start carries an explicit mode.
///
/// `useRootNavigator: true` - same as [JourneyRouteChoiceSheet] - so the
/// sheet is pushed above [AppShell]'s whole Stack rather than inside the
/// active tab's own nested Navigator: otherwise it renders underneath the
/// shell's floating [AppBottomNav], which sits in a later, higher
/// Positioned layer of that Stack.
abstract final class JourneyTransportModePicker {
  static Future<JourneyTransportMode?> choose(BuildContext context) {
    return showModalBottomSheet<JourneyTransportMode>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _TransportModeSheet(),
    );
  }
}

class _TransportModeSheet extends StatelessWidget {
  const _TransportModeSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How are you travelling?',
              style: AppTypeScale.sectionTitle,
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a mode for this Trip - it sharpens the route and '
              "shows on the Trip's card.",
              style: AppTypeScale.meta.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            for (final mode in JourneyTransportMode.values) ...[
              _ModeTile(mode: mode),
              if (mode != JourneyTransportMode.values.last)
                const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.mode});

  final JourneyTransportMode mode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.pageBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pop(mode),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(journeyTransportModeIcon(mode), color: AppColors.accent),
              const SizedBox(width: 14),
              Text(mode.label, style: AppTypeScale.cardTitle),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
