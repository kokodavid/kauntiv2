import 'dart:isolate';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/counties/county_boundary_resolver.dart';
import '../../../counties/county_paths.dart';
import '../../../services/app_logger.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/journey_moments.dart';
import '../domain/journey_point.dart';
import '../domain/journey_replay.dart';
import 'journey_cloud_providers.dart';
import 'journey_views.dart';

part 'journey_key_moments.g.dart';

const _logger = AppLogger.journeys();

/// The signed-in user's saved places, for spotting them along a replay.
/// Empty offline or without Supabase: the other moments still work.
@riverpod
Future<List<JourneyPlaceMark>> journeySavedPlaces(Ref ref) async {
  ref.watch(authUserIdProvider);
  final userId = ref.watch(currentUserIdProvider)();
  final cloud = ref.watch(supabaseJourneyRepositoryProvider);
  if (userId == null || cloud == null) return const [];
  try {
    return await cloud.savedPlaces(userId);
  } on Object catch (error, stackTrace) {
    _logger.warning(
      'Saved places unavailable for replay moments.',
      error: error,
      stackTrace: stackTrace,
    );
    return const [];
  }
}

/// A Journey's key moments, in replay order: recording breaks, long stops,
/// county crossings (from the bundled boundaries, so offline too) and
/// saved places passed.
@riverpod
Future<List<JourneyMoment>> journeyMoments(Ref ref, String id) async {
  final detail = await ref.watch(journeyDetailProvider(id).future);
  final places = await ref.watch(journeySavedPlacesProvider.future);
  final points = JourneyReplayTrack(detail.route).points;
  // County lookups over a long route are real work: keep it off the UI.
  return Isolate.run(() => _findMoments(points, places));
}

List<JourneyMoment> _findMoments(
  List<JourneyPoint> points,
  List<JourneyPlaceMark> places,
) {
  int? last;
  int? countyAt(double latitude, double longitude) {
    // Most points are in the same county as the one before: check it
    // first, then all counties.
    final previous = last;
    if (previous != null &&
        CountyBoundaryResolver.countyCodeFor(
              latitude: latitude,
              longitude: longitude,
              countyCodes: [previous],
            ) ==
            previous) {
      return previous;
    }
    final code = CountyBoundaryResolver.countyCodeFor(
      latitude: latitude,
      longitude: longitude,
    );
    if (code != null) last = code;
    return code;
  }

  final names = {
    for (final county in CountyPaths.all) county.code: county.name,
  };
  return JourneyMoments.find(
    points,
    countyAt: countyAt,
    countyName: (code) => names[code],
    places: places,
  );
}
