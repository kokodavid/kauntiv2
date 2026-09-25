import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/services/app_config_provider.dart';
import '../../../core/widgets/app_photo_parts.dart';
import '../../../design/app_colors.dart';
import '../application/journey_views.dart';
import '../domain/journey_point.dart';
import '../domain/journey_preview.dart';
import '../domain/journey_route.dart';
import '../domain/journey_summary.dart';

/// A past Journey in the list, in the place-card style: a map preview of
/// the route under a fade with the title and facts, Replay on the photo,
/// and when it started plus delete below.
class JourneyCard extends StatelessWidget {
  const JourneyCard({
    super.key,
    required this.journey,
    required this.onDelete,
    this.onOpen,
  });

  final JourneySummary journey;
  final VoidCallback? onOpen;
  final VoidCallback onDelete;

  static const _headerHeight = 180.0;

  @override
  Widget build(BuildContext context) {
    final started = journey.startedAt.toLocal();
    final day = JourneyTitles.defaultFor(
      started,
    ).replaceFirst('Journey on ', '');
    final time = TimeOfDay.fromDateTime(started).format(context);
    final facts = [
      JourneyFormat.duration(journey.duration),
      if (journey.isUploaded) JourneyFormat.distance(journey.distanceMeters),
    ].join(' · ');
    final open = onOpen;
    return GestureDetector(
      onTap: open,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: _headerHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _RoutePreview(journeyId: journey.id),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0x99000000), Color(0x00000000)],
                          stops: [0.0, 0.55],
                        ),
                      ),
                    ),
                    if (!journey.isUploaded)
                      const Positioned(
                        top: 10,
                        left: 10,
                        child: AppPhotoPill(label: 'Waiting to upload'),
                      ),
                    Positioned(
                      left: 12,
                      right: open == null ? 12 : 116,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            journey.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypeScale.photoTitle,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.route_rounded,
                                size: 13,
                                color: AppColors.heroSubheadingText,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  facts,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypeScale.photoCaption,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (open != null)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: AppPhotoButton(
                          onPressed: open,
                          label: 'Replay',
                          icon: Icons.play_arrow_rounded,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 0, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Started $time · $day',
                      style: AppTypeScale.small.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete Journey',
                    color: AppColors.mutedForeground,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The route on a Mapbox static map, or a plain fill while it loads,
/// offline, or in a build without a Mapbox token.
class _RoutePreview extends ConsumerWidget {
  const _RoutePreview({required this.journeyId});

  final String journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const fill = ColoredBox(
      color: AppColors.lockedFill,
      child: Center(
        child: Icon(
          Icons.route_rounded,
          size: 40,
          color: AppColors.lockedStroke,
        ),
      ),
    );
    final token = ref.watch(appConfigProvider).mapboxAccessToken;
    // No token, no preview: don't load the route for nothing.
    if (token.isEmpty) return fill;
    final route = ref.watch(journeyDetailProvider(journeyId)).value?.route;
    if (route == null || route.isEmpty) return fill;
    return LayoutBuilder(
      builder: (context, constraints) {
        final url = JourneyStaticMap.url(
          route,
          token: token,
          // Whole 40 px steps so rebuilds hit the image cache.
          width: (constraints.maxWidth / 40).ceil() * 40,
          height: constraints.maxHeight.round(),
        );
        return Image.network(
          url,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, synchronous) =>
              frame == null && !synchronous ? fill : child,
          errorBuilder: (context, error, stackTrace) => fill,
        );
      },
    );
  }
}

/// Mapbox Static Images URLs for a route preview. The route's (thinned)
/// coordinates go to Mapbox in the URL to draw it.
abstract final class JourneyStaticMap {
  /// Mapbox caps static images at 1280 px a side; @2x doubles the size.
  static const _maxSide = 640;

  static String url(
    JourneyRoute route, {
    required String token,
    required int width,
    required int height,
  }) {
    final accent = _hex(AppColors.accent);
    final segments = JourneyPreview.thin(route);
    final first = segments.first.first;
    final last = segments.last.last;
    final overlays = [
      for (final segment in segments)
        if (segment.length > 1)
          'path-4+$accent-1('
              '${Uri.encodeComponent(JourneyPreview.encode(segment))})',
      'pin-s+${_hex(AppColors.legendHome)}(${_at(first)})',
      'pin-s+${_hex(AppColors.danger)}(${_at(last)})',
    ].join(',');
    final w = width.clamp(80, _maxSide);
    final h = height.clamp(80, _maxSide);
    return 'https://api.mapbox.com/styles/v1/mapbox/outdoors-v12/static/'
        '$overlays/auto/${w}x$h@2x?padding=32&access_token=$token';
  }

  static String _at(JourneyPoint p) =>
      '${p.longitude.toStringAsFixed(5)},${p.latitude.toStringAsFixed(5)}';

  static String _hex(Color color) =>
      (color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
}
