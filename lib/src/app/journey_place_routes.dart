import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/domain/app_feature_flags.dart';
import '../core/domain/map_place.dart';
import '../features/discover/domain/place_detail.dart';
import '../features/journeys/application/journey_recorder.dart';
import '../features/journeys/domain/journey_destination.dart';
import '../features/journeys/domain/pro_status.dart';
import '../features/journeys/presentation/journey_messages.dart';
import '../features/map_home/domain/map_home_promotion.dart';
import 'detail_routes.dart';
import 'journey_route_choice_sheet.dart';

typedef _LaunchDirections = Future<bool> Function();

/// Place-to-Journey handoff. Navigation stays in app/; recording remains
/// owned by the Journeys feature and directions by Discover.
abstract final class JourneyPlaceRoutes {
  static Future<void> open(BuildContext context, PlaceDetailData place) =>
      _open(
        context,
        JourneyDestination(
          placeId: place.id,
          name: place.title,
          latitude: place.latitude,
          longitude: place.longitude,
        ),
        () => DetailRoutes.actions!.openDirections(place),
      );

  static Future<void> openMapPlace(BuildContext context, MapPlace place) =>
      _open(
        context,
        JourneyDestination(
          placeId: place.id,
          name: place.name,
          latitude: place.lat,
          longitude: place.lng,
        ),
        () => DetailRoutes.openDirections('${place.lat},${place.lng}'),
      );

  static Future<void> openPromotion(
    BuildContext context,
    MapHomePromotedPlace place,
  ) => _open(
    context,
    JourneyDestination(
      placeId: place.placeId,
      name: place.placeName,
      latitude: place.latitude,
      longitude: place.longitude,
    ),
    () => DetailRoutes.openDirections(place.directionsQuery),
  );

  static Future<void> _open(
    BuildContext context,
    JourneyDestination destination,
    _LaunchDirections launchDirections,
  ) async {
    if (!AppFeatureFlags.journeys) {
      await _openDirections(context, launchDirections);
      return;
    }

    final container = ProviderScope.containerOf(context, listen: false);
    if (container.read(journeyRecorderProvider) != null) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Journey already recording'),
          content: const Text(
            'Directions will open while your current Journey keeps '
            'recording. Its destination will not change.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Open directions'),
            ),
          ],
        ),
      );
      if (proceed == true && context.mounted) {
        await _openDirections(context, launchDirections);
      }
      return;
    }

    final choice = await JourneyRouteChoiceSheet.show(
      context,
      destination.name,
    );
    if (!context.mounted || choice == null) return;
    if (choice == JourneyRouteChoice.directions) {
      await _openDirections(context, launchDirections);
      return;
    }

    final recorder = container.read(journeyRecorderProvider.notifier);
    try {
      await recorder.start(destination: destination);
    } on Object catch (error) {
      if (context.mounted) {
        await _startFailed(context, launchDirections, error);
      }
      return;
    }

    final opened = await _tryDirections(launchDirections);
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
    _LaunchDirections launchDirections,
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
      await _openDirections(context, launchDirections);
    }
  }

  static Future<bool> _tryDirections(_LaunchDirections launchDirections) async {
    try {
      return await launchDirections();
    } on Object {
      return false;
    }
  }

  static Future<void> _openDirections(
    BuildContext context,
    _LaunchDirections launchDirections,
  ) async {
    final opened = await _tryDirections(launchDirections);
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
