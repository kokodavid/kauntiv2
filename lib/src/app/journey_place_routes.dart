import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/domain/app_feature_flags.dart';
import '../features/discover/domain/place_detail.dart';
import '../features/journeys/application/journey_recorder.dart';
import '../features/journeys/domain/journey_destination.dart';
import '../features/journeys/domain/pro_status.dart';
import '../features/journeys/presentation/journey_messages.dart';
import 'detail_routes.dart';

enum _RouteChoice { record, directions }

/// Place-to-Journey handoff. Navigation stays in app/; recording remains
/// owned by the Journeys feature and directions by Discover.
abstract final class JourneyPlaceRoutes {
  static Future<void> open(BuildContext context, PlaceDetailData place) async {
    if (!AppFeatureFlags.journeys) {
      await _openDirections(context, place);
      return;
    }

    final container = ProviderScope.containerOf(context, listen: false);
    if (container.read(journeyRecorderProvider) != null) {
      _message(context, 'Your current Journey is already recording.');
      await _openDirections(context, place);
      return;
    }

    final choice = await showModalBottomSheet<_RouteChoice>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Go to ${place.title}'),
            ),
            ListTile(
              leading: const Icon(Icons.route_rounded),
              title: const Text('Record as a Journey'),
              subtitle: const Text(
                'Record privately, even while directions are open. '
                'Stop it yourself when you finish.',
              ),
              onTap: () => Navigator.of(sheetContext).pop(_RouteChoice.record),
            ),
            ListTile(
              leading: const Icon(Icons.directions_rounded),
              title: const Text('Directions only'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_RouteChoice.directions),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == _RouteChoice.directions) {
      await _openDirections(context, place);
      return;
    }

    final recorder = container.read(journeyRecorderProvider.notifier);
    try {
      await recorder.start(
        destination: JourneyDestination(
          placeId: place.id,
          name: place.title,
          latitude: place.latitude,
          longitude: place.longitude,
        ),
      );
    } on Object catch (error) {
      if (context.mounted) await _startFailed(context, place, error);
      return;
    }

    final opened = await _tryDirections(place);
    if (opened) return;
    var stopped = false;
    try {
      await recorder.discard();
      stopped = true;
    } on Object {
      // A failed native stop must remain visible as a recording to retry.
    }
    if (context.mounted) {
      _message(
        context,
        stopped
            ? "Couldn't open directions. The Journey was stopped."
            : "Couldn't open directions. Your Journey is still recording; "
                  'stop it in Journeys.',
      );
    }
  }

  static Future<void> _startFailed(
    BuildContext context,
    PlaceDetailData place,
    Object error,
  ) async {
    final directionsOnly = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          error is JourneyStartDenied
              ? JourneyMessages.proRequiredTitle
              : "Couldn't record a Journey",
        ),
        content: Text(
          error is JourneyStartDenied
              ? JourneyMessages.proRequiredBody
              : JourneyMessages.forError(error) ?? 'Try again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Directions only'),
          ),
        ],
      ),
    );
    if (directionsOnly == true && context.mounted) {
      await _openDirections(context, place);
    }
  }

  static Future<bool> _tryDirections(PlaceDetailData place) async {
    try {
      return await DetailRoutes.actions!.openDirections(place);
    } on Object {
      return false;
    }
  }

  static Future<void> _openDirections(
    BuildContext context,
    PlaceDetailData place,
  ) async {
    final opened = await _tryDirections(place);
    if (!opened && context.mounted) {
      _message(context, "Couldn't open directions.");
    }
  }

  static void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
