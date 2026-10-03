import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_county_shape.dart';
import '../domain/journey_transport_mode.dart';
import 'journey_transport_mode_ui.dart';

part 'trip_share_card_thumbnail_content.dart';
part 'trip_share_card_share_content.dart';
part 'trip_share_card_county_block.dart';
part 'trip_share_card_county_names_line.dart';
part 'trip_share_card_stat_cell.dart';
part 'trip_share_card_stat_grid.dart';
part 'trip_share_card_date_chip.dart';
part 'trip_share_card_watermark.dart';
part 'trip_share_card_bottom_scrim.dart';
part 'trip_share_card_top_scrim.dart';
part 'trip_share_card_no_photo_background.dart';
part 'trip_share_card_route_line_painter.dart';
part 'trip_share_card_trip_share_date.dart';
part 'trip_share_card_trip_share_stats.dart';
part 'trip_share_card_styles.dart';

/// Where a [TripShareCard] is used: the wide in-app history-card
/// thumbnail, or one of the taller share-out sizes (Instagram feed 4:5,
/// Stories 9:16). Both tall sizes use this one "share" arrangement,
/// differing only in outer padding (see [TripShareCard._contentPadding])
/// - only the label verbosity and whether the Trip title shows differ
/// between [thumbnail] and [share] themselves.

enum TripShareCardVariant { thumbnail, share }

/// The generated Trip image used both as the history card's background
/// (replacing the old Mapbox route-preview fetch) and as the file handed
/// to the OS share sheet (Claude-Design "Trip Share Card" reference).
///
/// Pure layout: this widget only draws, from already-resolved data. It
/// doesn't decide which photo to use, fetch it, or rasterize itself to a
/// PNG - that's the renderer built on top of it next.
class TripShareCard extends StatelessWidget {
  const TripShareCard({
    super.key,
    required this.variant,
    required this.width,
    required this.height,
    required this.title,
    required this.startedAt,
    required this.endedAt,
    this.transportMode,
    this.distanceMeters,
    this.topSpeedMps,
    this.averageSpeedMps,
    this.highestElevationMeters,
    this.countyNames = const [],
    this.photo,
    this.routePoints = const [],
  });

  final TripShareCardVariant variant;

  /// The card's exact logical size - 342x171 for the history-card
  /// thumbnail, 360x450 for a 4:5 feed share, 360x640 for a 9:16 Story
  /// share (Claude-Design "Trip Share Card" reference). Exporting to a
  /// higher-resolution PNG (the design calls for 3x) is the renderer's
  /// job, not this widget's - it only ever lays out at its logical size.
  final double width;
  final double height;

  /// Shown only in the [TripShareCardVariant.share] layout - the
  /// thumbnail has no room for it alongside the stat grid.
  final String title;

  final DateTime startedAt;
  final DateTime endedAt;
  final JourneyTransportMode? transportMode;
  final double? distanceMeters;
  final double? topSpeedMps;
  final double? averageSpeedMps;
  final double? highestElevationMeters;

  /// Counties the Trip crossed, in trip order. The count shown ("5
  /// counties") is just this list's length - there's no separate count
  /// field to keep in sync.
  final List<String> countyNames;

  /// The Trip's cover photo, already resolved - null shows the no-photo
  /// brand gradient instead. Resolving *which* photo (the user's chosen
  /// cover, falling back to the Trip's earliest) and fetching it is the
  /// caller's job.
  final ImageProvider? photo;

  /// The route's points, already normalized to a unit square - see
  /// [normalizeRoute] - for the no-photo fallback's route line. Ignored
  /// whenever [photo] is set.
  final List<Offset> routePoints;

  /// Normalizes a route's (lat, lng) points to a unit square: (0,0) is
  /// the top-left of its own bounding box, (1,1) the bottom-right,
  /// aspect-ratio preserved (the shorter axis is centered rather than
  /// stretched to fill the square). Lets the no-photo painter place a
  /// route anywhere at any size without knowing real coordinates.
  /// Returns an empty list for a route with no real span - nothing
  /// meaningful to draw.
  static List<Offset> normalizeRoute(List<(double lat, double lng)> points) {
    if (points.length < 2) return const [];
    var minLat = points.first.$1, maxLat = points.first.$1;
    var minLng = points.first.$2, maxLng = points.first.$2;
    for (final (lat, lng) in points) {
      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLng = math.min(minLng, lng);
      maxLng = math.max(maxLng, lng);
    }
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;
    final span = math.max(latSpan, lngSpan);
    if (span == 0) return const [];
    final latPad = (span - latSpan) / 2;
    final lngPad = (span - lngSpan) / 2;
    return [
      for (final (lat, lng) in points)
        Offset(
          (lng - minLng + lngPad) / span,
          // Screen y grows downward; latitude grows northward, so flip.
          1 - (lat - minLat + latPad) / span,
        ),
    ];
  }

  bool get _isShare => variant == TripShareCardVariant.share;

  /// True for the taller, narrower Stories shape (9:16) rather than the
  /// Feed shape (4:5) - both are [TripShareCardVariant.share], told
  /// apart only by how tall they are relative to their width, since
  /// nothing else about this widget's inputs differs between them.
  bool get _isStory => height / width > 1.5;

  EdgeInsets get _contentPadding {
    if (!_isShare) return const EdgeInsets.all(14);
    // Stories safe zone (Claude-Design reference): keep clear of the
    // top/bottom strips where Instagram and WhatsApp draw their own UI.
    return _isStory
        ? const EdgeInsets.fromLTRB(20, 72, 20, 104)
        : const EdgeInsets.all(22);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo != null;
    final dateLabel = _TripShareDate.format(
      startedAt,
      endedAt,
      includeYear: _isShare,
    );
    final icon = transportMode == null
        ? null
        : journeyTransportModeIcon(transportMode!);
    final distance = _TripShareStats.distance(distanceMeters);
    final topSpeed = _TripShareStats.speed(topSpeedMps);
    final avgSpeed = _TripShareStats.speed(averageSpeedMps);
    final peak = _TripShareStats.elevation(highestElevationMeters);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              Image(image: photo!, fit: BoxFit.cover)
            else
              _NoPhotoBackground(routePoints: routePoints, isShare: _isShare),
            // Always present; lighter over the brand gradient than over
            // a real photo, which can be far busier or brighter.
            _BottomScrim(strength: hasPhoto ? 1 : 0.6),
            _TopScrim(strength: hasPhoto ? 1 : 0.6),
            Padding(
              padding: _contentPadding,
              child: _isShare
                  ? _ShareContent(
                      title: title,
                      dateLabel: dateLabel,
                      icon: icon,
                      watermarkInverted: !hasPhoto,
                      countyNames: countyNames,
                      distance: distance,
                      topSpeed: topSpeed,
                      avgSpeed: avgSpeed,
                      peak: peak,
                    )
                  : _ThumbnailContent(
                      dateLabel: dateLabel,
                      icon: icon,
                      watermarkInverted: !hasPhoto,
                      countyNames: countyNames,
                      distance: distance,
                      topSpeed: topSpeed,
                      avgSpeed: avgSpeed,
                      peak: peak,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
