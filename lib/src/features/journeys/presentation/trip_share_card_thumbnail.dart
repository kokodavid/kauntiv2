import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/app_logger.dart';
import '../application/journey_views.dart';
import '../application/trip_share_card_cache_provider.dart';
import '../domain/journey_media_capture.dart';
import '../domain/journey_route.dart';
import '../domain/journey_summary.dart';
import 'journey_card.dart' show JourneyRoutePreview;
import 'trip_share_card.dart';
import 'trip_share_card_renderer.dart';

/// Drop-in replacement for [JourneyRoutePreview] in the Trip history
/// card: generates and caches a [TripShareCard] PNG from the Trip's
/// stats and its resolved cover photo (Phase 5), falling back to the
/// plain Mapbox route preview for a Trip that isn't uploaded yet (no
/// synced photos to choose a cover from) or if generation fails for any
/// reason - this must never be the thing that breaks the history list.
class TripShareCardThumbnail extends ConsumerStatefulWidget {
  const TripShareCardThumbnail({super.key, required this.journeyId});

  final String journeyId;

  @override
  ConsumerState<TripShareCardThumbnail> createState() =>
      _TripShareCardThumbnailState();
}

class _TripShareCardThumbnailState
    extends ConsumerState<TripShareCardThumbnail> {
  static const _logger = AppLogger.journeys();

  File? _cached;
  String? _generatedFor;
  String? _pendingFor;
  String? _failedFor;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(journeyDetailProvider(widget.journeyId)).value;
    final summary = detail?.summary;
    final media =
        ref.watch(journeyMediaProvider(widget.journeyId)).value ?? const [];

    if (summary == null || detail == null || !summary.isUploaded) {
      return JourneyRoutePreview(journeyId: widget.journeyId);
    }

    final cache = ref.read(tripShareCardCacheAccessProvider);
    final cover = cache.resolveCoverPhoto(summary, media);
    // No synced photo to build a share card from: the generated
    // no-photo variant (route line over a flat colour fill) read as a
    // plain blue block at thumbnail size, worse than just showing the
    // Trip's own route preview directly - so skip generation entirely
    // for these rather than rendering (and caching) that fallback.
    if (cover == null) {
      return JourneyRoutePreview(journeyId: widget.journeyId);
    }

    // Generate at this exact slot's own size: JourneyCard's header's real
    // on-screen width, with a fixed 208 height - not the 342x171 this
    // used to hardcode. That box is wider/shorter than 342x171 (closer
    // to 1.6:1 than 2:1), so Image.file below was
    // forced to zoom BoxFit.cover in to fill the taller slot, cropping
    // the card's left and right edges - the watermark, county names and
    // stat grid all trimmed at the sides. Drawing straight at the real
    // box's dimensions means the card's own internal layout (which
    // already flexes with Spacers rather than fixed positions) fills it
    // exactly, with nothing to crop.
    return LayoutBuilder(
      builder: (context, constraints) {
        final renderSize = constraints.biggest;
        final signature = cache.signatureFor(
          summary,
          cover,
          renderWidth: renderSize.width,
          renderHeight: renderSize.height,
        );

        final needsGeneration =
            signature != _generatedFor &&
            signature != _pendingFor &&
            signature != _failedFor;
        if (needsGeneration) {
          _pendingFor = signature;
          final route = detail.route;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            unawaited(_generate(summary, cover, signature, route, renderSize));
          });
        }

        final cached = _cached;
        if (cached == null) {
          return JourneyRoutePreview(journeyId: widget.journeyId);
        }
        return Image.file(
          cached,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              child: child,
            );
          },
        );
      },
    );
  }

  Future<void> _generate(
    JourneySummary summary,
    JourneyMediaItem? cover,
    String signature,
    JourneyRoute route,
    Size renderSize,
  ) async {
    try {
      final cache = ref.read(tripShareCardCacheAccessProvider);
      final cachedPath = await cache.readIfFresh(widget.journeyId, signature);
      if (cachedPath != null) {
        _settle(cached: File(cachedPath), signature: signature);
        return;
      }

      final photo = cover == null ? null : NetworkImage(cover.url);
      if (photo != null && mounted) {
        await precacheImage(photo, context);
      }
      if (!mounted) return;

      final routePoints = photo == null
          ? TripShareCard.normalizeRoute(cache.mainRoutePoints(route))
          : const <Offset>[];

      final bytes = await captureTripShareCard(
        context: context,
        card: TripShareCard(
          variant: TripShareCardVariant.thumbnail,
          width: renderSize.width,
          height: renderSize.height,
          title: summary.title,
          startedAt: summary.startedAt,
          endedAt: summary.endedAt,
          transportMode: summary.transportMode,
          distanceMeters: summary.distanceMeters,
          topSpeedMps: summary.topSpeedMps,
          averageSpeedMps: summary.averageSpeedMps,
          highestElevationMeters: summary.highestElevationMeters,
          countyNames: summary.countyNames,
          photo: photo,
          routePoints: routePoints,
        ),
      );
      final path = await cache.write(widget.journeyId, signature, bytes);
      _settle(cached: File(path), signature: signature);
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Trip share card thumbnail generation failed for '
        '${widget.journeyId}',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _pendingFor = null;
        _failedFor = signature;
      });
    }
  }

  void _settle({required File cached, required String signature}) {
    if (!mounted) return;
    setState(() {
      _cached = cached;
      _generatedFor = signature;
      _pendingFor = null;
      _failedFor = null;
    });
  }
}
