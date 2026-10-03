import 'dart:isolate';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/counties/county_boundary_resolver.dart';
import '../../../core/domain/map_place.dart';
import '../../../core/services/supabase_client_provider.dart';
import '../../../counties/county_paths.dart';
import '../../badges/application/badges_providers.dart';
import '../../badges/domain/badge_collection.dart';
import '../data/journey_county_facts_repository.dart';
import '../domain/journey_county_moment_facts.dart';
import '../domain/journey_media_capture.dart';
import '../domain/journey_moments.dart';
import '../domain/journey_point.dart';
import '../domain/journey_replay.dart';
import 'journey_cloud_providers.dart';
import 'journey_views.dart';

part 'journey_key_moments.g.dart';

/// Kaunti47 places as map pins for the map while recording (same pins as
/// Home). Kept for the session: places change rarely.
@Riverpod(keepAlive: true)
Future<List<MapPlace>> journeyMapPlaces(Ref ref) async {
  final cloud = ref.watch(supabaseJourneyRepositoryProvider);
  if (cloud == null) return const [];
  return cloud.mapPlaces();
}

/// A Journey's key moments, in replay order: recording breaks, long stops,
/// county crossings (from the bundled boundaries, so offline too), photos
/// and the Trip's elevation peak.
@riverpod
Future<List<JourneyMoment>> journeyMoments(Ref ref, String id) async {
  final detail = await ref.watch(journeyDetailProvider(id).future);
  final photos = await ref.watch(journeyMediaProvider(id).future);
  final points = JourneyReplayTrack(detail.route).points;
  // County lookups over a long route are real work: keep it off the UI.
  return Isolate.run(() => _findMoments(points, photos));
}

/// Batched county facts in the cloud, or null when the build has no
/// Supabase.
@riverpod
JourneyCountyFactsRepository? journeyCountyFactsRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : JourneyCountyFactsRepository(client);
}

/// The "Entered county" card's data for every county this Trip crossed,
/// keyed by county code. Static facts and the visit count come from one
/// batched query; [JourneyCountyMomentFacts.depth] is merged in from the
/// Badges collection already loaded elsewhere, so this never re-derives
/// the depth ladder from scratch.
@riverpod
Future<Map<int, JourneyCountyMomentFacts>> journeyCountyMomentFacts(
  Ref ref,
  String id,
) async {
  final moments = await ref.watch(journeyMomentsProvider(id).future);
  final codes = {
    for (final moment in moments)
      if (moment.kind == JourneyMomentKind.countyCrossing &&
          moment.countyCode != null)
        moment.countyCode!,
  };
  if (codes.isEmpty) return const {};
  final repository = ref.watch(journeyCountyFactsRepositoryProvider);
  if (repository == null) return const {};
  final facts = await repository.factsFor(codes);
  final collection = await ref.watch(badgeCollectionProvider.future);
  final depthByCounty = {
    for (final badge in collection.badges) badge.county.code: badge.depth,
  };
  return {
    for (final entry in facts.entries)
      entry.key: JourneyCountyMomentFacts(
        capital: entry.value.capital,
        population: entry.value.population,
        rarityPct: entry.value.rarityPct,
        highlightImageUrl: entry.value.highlightImageUrl,
        placesCount: entry.value.placesCount,
        firstPlaceThumbnailUrl: entry.value.firstPlaceThumbnailUrl,
        passCount: entry.value.passCount,
        depth: depthByCounty[entry.key] ?? CountyDepth.none,
      ),
  };
}

List<JourneyMoment> _findMoments(
  List<JourneyPoint> points,
  List<JourneyMediaItem> photos,
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
              minimumInsideDistanceMeters:
                  CountyBoundaryResolver.boundaryHysteresisMeters,
            ) ==
            previous) {
      return previous;
    }
    final code = CountyBoundaryResolver.countyCodeFor(
      latitude: latitude,
      longitude: longitude,
      minimumInsideDistanceMeters:
          CountyBoundaryResolver.boundaryHysteresisMeters,
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
    photos: photos,
  );
}
