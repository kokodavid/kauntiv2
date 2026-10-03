import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/trip_share_card_cache.dart';
import '../domain/journey_media_capture.dart';
import '../domain/journey_route.dart';
import '../domain/journey_summary.dart';

part 'trip_share_card_cache_provider.g.dart';

@riverpod
TripShareCardCacheAccess tripShareCardCacheAccess(Ref ref) =>
    const TripShareCardCacheAccess();

class TripShareCardCacheAccess {
  const TripShareCardCacheAccess();

  JourneyMediaItem? resolveCoverPhoto(
    JourneySummary summary,
    List<JourneyMediaItem> media,
  ) => TripShareCardCache.resolveCoverPhoto(summary, media);

  String signatureFor(
    JourneySummary summary,
    JourneyMediaItem? cover, {
    double? renderWidth,
    double? renderHeight,
  }) => TripShareCardCache.signatureFor(
    summary,
    cover,
    renderWidth: renderWidth,
    renderHeight: renderHeight,
  );

  List<(double, double)> mainRoutePoints(JourneyRoute route) =>
      TripShareCardCache.mainRoutePoints(route);

  Future<String?> readIfFresh(
    String journeyId,
    String signature, {
    String suffix = '',
  }) async => (await TripShareCardCache.readIfFresh(
    journeyId,
    signature,
    suffix: suffix,
  ))?.path;

  Future<String> write(
    String journeyId,
    String signature,
    Uint8List bytes, {
    String suffix = '',
  }) async => (await TripShareCardCache.write(
    journeyId,
    signature,
    bytes,
    suffix: suffix,
  )).path;

  Future<void> invalidate(String journeyId) =>
      TripShareCardCache.invalidate(journeyId);
}
