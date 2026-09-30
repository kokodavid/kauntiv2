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

part 'journey_card_parts.dart';

/// A past Trip in the list, styled like a small stack of photos in a
/// folder: two tinted layers peek out from behind the main card to give
/// it depth, with a route-preview photo, title and facts on top, Replay
/// on the photo, and Rename/Delete in a menu below (not loose on the
/// card face).
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
                                const SizedBox(height: 5),
                                _FactsPill(facts: facts),
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
                    padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
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
                        PopupMenuButton<_JourneyCardAction>(
                          tooltip: 'Trip options',
                          icon: const Icon(
                            Icons.more_horiz,
                            color: AppColors.mutedForeground,
                          ),
                          onSelected: (action) => switch (action) {
                            _JourneyCardAction.rename => widget.onRename(),
                            _JourneyCardAction.delete => widget.onDelete(),
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _JourneyCardAction.rename,
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Rename'),
                              ),
                            ),
                            PopupMenuItem(
                              value: _JourneyCardAction.delete,
                              child: ListTile(
                                leading: Icon(
                                  Icons.delete_outline,
                                  color: AppColors.danger,
                                ),
                                title: Text(
                                  'Delete',
                                  style: TextStyle(color: AppColors.danger),
                                ),
                              ),
                            ),
                          ],
                        ),
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
enum _JourneyCardAction { rename, delete }

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
