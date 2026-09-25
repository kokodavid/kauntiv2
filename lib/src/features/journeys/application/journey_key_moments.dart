import 'dart:isolate';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/counties/county_boundary_resolver.dart';
import '../../../core/domain/map_place.dart';
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

/// Kaunti47 places (with the user's saved ones marked), for spotting
/// those near a replayed route. Empty offline or without Supabase: the
/// other moments still work.
@riverpod
Future<List<JourneyPlaceMark>> journeyPlaces(Ref ref) async {
  ref.watch(authUserIdProvider);
  final userId = ref.watch(currentUserIdProvider)();
  final cloud = ref.watch(supabaseJourneyRepositoryProvider);
  if (userId == null || cloud == null) return const [];
  try {
    return await cloud.places(userId);
  } on Object catch (error, stackTrace) {
    _logger.warning(
      'Places unavailable for replay moments.',
      error: error,
      stackTrace: stackTrace,
    );
    return const [];
  }
}

/// Kaunti47 places as map pins for the map while recording (same pins as
/// Home). Kept for the session: places change rarely.
@Riverpod(keepAlive: true)
Future<List<MapPlace>> journeyMapPlaces(Ref ref) async {
  final cloud = ref.watch(supabaseJourneyRepositoryProvider);
  if (cloud == null) return const [];
  return cloud.mapPlaces();
}

/// A Journey's key moments, in replay order: recording breaks, long stops,
/// county crossings (from the bundled boundaries, so offline too) and
/// places within 10 km.
@riverpod
Future<List<JourneyMoment>> journeyMoments(Ref ref, String id) async {
  final detail = await ref.watch(journeyDetailProvider(id).future);
  final places = await ref.watch(journeyPlacesProvider.future);
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
