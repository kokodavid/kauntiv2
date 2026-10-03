import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/services/app_config_provider.dart';
import '../../../core/widgets/app_actions_menu.dart';
import '../../../core/widgets/app_photo_parts.dart';
import '../../../design/app_colors.dart';
import '../application/journey_views.dart';
import '../domain/journey_point.dart';
import '../domain/journey_preview.dart';
import '../domain/journey_route.dart';
import '../domain/journey_summary.dart';
import 'journey_transport_mode_ui.dart';
import 'trip_share_card_thumbnail.dart';

part 'journey_card_parts.dart';

/// A past Trip in the list, styled like a small stack of photos in a
/// folder: two tinted layers peek out from behind the main card to give
/// it depth, a generated Trip share image (see [TripShareCardThumbnail])
/// as its header - already carrying the Trip's own stats - title and a
/// short caption below it, and Rename/Delete in a menu there (not loose
/// on the card face). Tapping anywhere on the card opens Replay; there's
/// no separate button for it now that the header has no empty space to
/// float one over.
class JourneyCard extends StatefulWidget {
  const JourneyCard({
    super.key,
    required this.journey,
    required this.onRename,
    required this.onDelete,
    this.onOpen,
  });

  final JourneySummary journey;
  final VoidCallback? onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  static const _headerHeight = 208.0;

  @override
  State<JourneyCard> createState() => _JourneyCardState();
}

class _JourneyCardState extends State<JourneyCard> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final journey = widget.journey;
    final started = journey.startedAt.toLocal();
    final day = JourneyTitles.defaultFor(started).replaceFirst('Trip on ', '');
    final time = TimeOfDay.fromDateTime(started).format(context);
    final facts = [
      JourneyFormat.duration(journey.duration),
      if (journey.isUploaded) JourneyFormat.distance(journey.distanceMeters),
    ].join(' · ');
    final open = widget.onOpen;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The folder-stack depth: two tinted layers peeking from behind
        // the bottom edge, so a pile of past Trips reads like a stack of
        // photos rather than a flat list.
        const Positioned(
          left: 22,
          right: 6,
          bottom: -6,
          child: _StackPeek(color: AppColors.trackInactive),
        ),
        const Positioned(
          left: 12,
          right: 2,
          bottom: -3,
          child: _StackPeek(color: AppColors.lockedFill),
        ),
        AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: GestureDetector(
            onTap: open,
            onTapDown: open == null ? null : (_) => _setPressed(true),
            onTapCancel: open == null ? null : () => _setPressed(false),
            onTapUp: open == null ? null : (_) => _setPressed(false),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14606060),
                    offset: Offset(0, 6),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: JourneyCard._headerHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // The generated Trip share image (Claude-Design
                          // "Trip Share Card") already carries the Trip's
                          // stats and a scrim for legibility, so this
                          // header no longer needs its own title/facts
                          // overlay or gradient - only the "waiting to
                          // upload" pill, which TripShareCardThumbnail
                          // itself doesn't know about. A Trip not yet
                          // uploaded (and therefore without synced
                          // photos to build a share card from) still
                          // falls back to the plain route-map preview
                          // inside TripShareCardThumbnail.
                          TripShareCardThumbnail(journeyId: journey.id),
                          if (!journey.isUploaded)
                            Positioned(
                              top: 10,
                              left: 10,
                              child: AppPhotoPill(
                                label: journey.blockedByTrialLimit
                                    ? 'Free limit reached'
                                    : 'Waiting to upload',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          journey.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypeScale.cardTitle,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                // Distance/duration moved here from the
                                // old on-photo facts pill - the share
                                // card's own stat grid already shows
                                // distance, so this line is now just a
                                // caption under the title rather than a
                                // second place to read the same number.
                                'Started $time · $day · $facts',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypeScale.small.copyWith(
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ),
                            AppActionsMenuButton(
                              tooltip: 'Trip options',
                              actions: [
                                AppMenuAction(
                                  label: 'Rename',
                                  icon: Icons.edit_outlined,
                                  onTap: widget.onRename,
                                ),
                                AppMenuAction(
                                  label: 'Delete',
                                  icon: Icons.delete_outline,
                                  isDestructive: true,
                                  onTap: widget.onDelete,
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (journey.countyNames.isNotEmpty ||
                            journey.transportMode != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (journey.countyNames.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    journey.countyNames.join(' → '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypeScale.small.copyWith(
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                ),
                              if (journey.transportMode case final mode?)
                                Icon(
                                  journeyTransportModeIcon(mode),
                                  size: 16,
                                  color: AppColors.mutedForeground,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A thin tinted layer peeking out behind the main card, suggesting
/// another photo underneath it in the stack.
class _StackPeek extends StatelessWidget {
  const _StackPeek({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
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
          'path-4+$accent-1(${Uri.encodeComponent(JourneyPreview.encode(segment))})',
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
