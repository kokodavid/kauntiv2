import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/journeys/domain/journey_destination.dart';
import '../features/trip_plans/application/plan_recordings.dart';
import '../features/trip_plans/application/trip_plans_providers.dart';
import '../features/trip_plans/domain/plan_day.dart';
import '../features/trip_plans/domain/trip_plan.dart';
import 'journey_place_routes.dart';

/// Start trip on a plan day: the Journeys feature records, Maps shows the
/// way, and the new Trip is linked to the day so the plan can show it as
/// recorded. Plans and Journeys stay apart; they meet here.
Future<void> startPlanDay(
  BuildContext context,
  TripPlan plan,
  PlanDay day,
) async {
  final stops = [
    for (final stop in day.stops)
      if (stop.place.hasPosition)
        JourneyStop(
          placeId: stop.place.id,
          name: stop.place.name,
          latitude: stop.place.lat!,
          longitude: stop.place.lng!,
        ),
  ];
  if (stops.isEmpty) return;
  final destination = stops.last;
  final via = stops.take(stops.length - 1).toList();
  final container = ProviderScope.containerOf(context, listen: false);
  await JourneyPlaceRoutes.startPlanDay(
    context,
    destination: JourneyDestination(
      placeId: destination.placeId,
      name: destination.name,
      latitude: destination.latitude,
      longitude: destination.longitude,
      viaStops: via.take(JourneyDestination.maxViaStops).toList(),
    ),
    // Maps takes about 9 stops on the way; the Trip keeps them all.
    waypoints: [for (final s in via.take(9)) '${s.latitude},${s.longitude}'],
    onStarted: (journeyId) =>
        unawaited(_link(container, plan, day, journeyId)),
  );
}

Future<void> _link(
  ProviderContainer container,
  TripPlan plan,
  PlanDay day,
  String journeyId,
) async {
  try {
    await container
        .read(tripPlansRepositoryProvider)
        ?.linkDayRecording(day.id, journeyId);
    container.invalidate(planRecordingsProvider(plan.id));
  } on Object {
    // The Trip is recording either way; only the link back is missed.
  }
}
