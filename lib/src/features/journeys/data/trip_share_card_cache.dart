import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../domain/journey_media_capture.dart';
import '../domain/journey_preview.dart';
import '../domain/journey_route.dart';
import '../domain/journey_summary.dart';

/// Resolves a Trip's cover photo, builds the signature that says whether
/// a previously-rendered [TripShareCard] PNG is still valid, and persists
/// that PNG to disk so it's only rendered once per (Trip, cover photo,
/// stats) combination rather than on every rebuild.
///
/// Plain static methods, not a `@riverpod` provider - this feature avoids
/// adding new codegen providers (see the renderer/thumbnail files) since
/// `build_runner` isn't available while this is being built. Mirrors the
/// file-based persistence [LocalJourneyMediaRepository] already uses
/// (`getApplicationSupportDirectory()` + a feature-named subfolder).
abstract final class TripShareCardCache {
  static Future<Directory> _directory() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/trip_share_cards');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> _pngFile(String journeyId, String suffix) async =>
      File('${(await _directory()).path}/$journeyId$suffix.png');

  static Future<File> _sigFile(String journeyId, String suffix) async =>
      File('${(await _directory()).path}/$journeyId$suffix.sig');

  /// The photo a Trip's share card should show: the user's explicit
  /// choice (`summary.coverMediaId`) when it's still among this Trip's
  /// synced photos, else the earliest one, else null (no-photo
  /// fallback). `media` is already ordered oldest-first by the server
  /// query, so "earliest" is just its first element.
  static JourneyMediaItem? resolveCoverPhoto(
    JourneySummary summary,
    List<JourneyMediaItem> media,
  ) {
    if (media.isEmpty) return null;
    final chosenId = summary.coverMediaId;
    if (chosenId != null) {
      for (final item in media) {
        if (item.id == chosenId) return item;
      }
    }
    return media.first;
  }

  /// Bump whenever [TripShareCard]'s own layout/painting changes in a way
  /// that should invalidate every already-cached PNG, even though none
  /// of [signatureFor]'s Trip-data inputs changed. Without this, a PNG
  /// rendered under an older version of the card (e.g. captured before
  /// the stat overlay was finished) matches its Trip's signature forever
  /// and keeps being served as "fresh" - this is what let plain,
  /// overlay-less cards cached early in development stick around
  /// instead of ever being regenerated.
  static const _renderVersion = 'v5';

  /// A string that changes whenever anything the rendered PNG depends on
  /// changes - plain equality, no hashing needed, since it's only ever
  /// compared to itself.
  ///
  /// [renderSize] is the thumbnail's own: [TripShareCardThumbnail] now
  /// generates at its real on-screen slot size (the card header's actual
  /// width, its fixed height) instead of a hardcoded constant, so that
  /// size has to be part of the signature too - otherwise a Trip whose
  /// slot size changes (a different device, an orientation change) would
  /// keep serving a PNG drawn for the old size, right back to
  /// `BoxFit.cover` cropping its edges to fit. The fixed-shape share/save
  /// renders don't go through this cache at all, so they don't pass it.
  static String signatureFor(
    JourneySummary summary,
    JourneyMediaItem? cover, {
    double? renderWidth,
    double? renderHeight,
  }) {
    return [
      _renderVersion,
      summary.title,
      summary.startedAt.toIso8601String(),
      summary.endedAt.toIso8601String(),
      summary.transportMode?.name ?? '-',
      summary.distanceMeters?.toString() ?? '-',
      summary.topSpeedMps?.toString() ?? '-',
      summary.averageSpeedMps?.toString() ?? '-',
      summary.highestElevationMeters?.toString() ?? '-',
      summary.countyNames.join('|'),
      cover?.id ?? '-',
      if (renderWidth != null && renderHeight != null)
        '${renderWidth.round()}x${renderHeight.round()}',
    ].join('::');
  }

  /// The Trip's longest route segment, thinned and ready for
  /// [TripShareCard.normalizeRoute] - only meaningful for the no-photo
  /// fallback's route line, so callers only need this when there's no
  /// cover photo to show instead.
  static List<(double, double)> mainRoutePoints(JourneyRoute route) {
    final segments = JourneyPreview.thin(route);
    if (segments.isEmpty) return const [];
    final largest = segments.reduce((a, b) => a.length >= b.length ? a : b);
    return [for (final p in largest) (p.latitude, p.longitude)];
  }

  /// The cached PNG for `journeyId`/`suffix` if its signature still
  /// matches, else null (either nothing cached yet, or something about
  /// the Trip changed since it was rendered).
  ///
  /// [suffix] keeps the history-card thumbnail and any full-resolution
  /// share renders from overwriting each other in the cache (e.g.
  /// `''` for the thumbnail, `'_feed'` / `'_story'` for share sizes).
  static Future<File?> readIfFresh(
    String journeyId,
    String signature, {
    String suffix = '',
  }) async {
    final sig = await _sigFile(journeyId, suffix);
    if (!sig.existsSync()) return null;
    final stored = await sig.readAsString();
    if (stored != signature) return null;
    final png = await _pngFile(journeyId, suffix);
    if (!png.existsSync()) return null;
    return png;
  }

  static Future<File> write(
    String journeyId,
    String signature,
    Uint8List bytes, {
    String suffix = '',
  }) async {
    final png = await _pngFile(journeyId, suffix);
    await png.writeAsBytes(bytes, flush: true);
    await (await _sigFile(journeyId, suffix)).writeAsString(signature);
    return png;
  }

  /// Forces the next read to regenerate - e.g. after the user changes
  /// the cover photo via `setCoverPhoto`, invalidate every cached size
  /// for that Trip (not just the thumbnail) since they all embed the
  /// same photo.
  static Future<void> invalidate(String journeyId) async {
    for (final suffix in const ['', '_feed', '_story']) {
      final sig = await _sigFile(journeyId, suffix);
      if (sig.existsSync()) await sig.delete();
    }
  }
}
