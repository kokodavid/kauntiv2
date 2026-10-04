import 'package:flutter/material.dart';

import '../../../core/domain/map_place.dart';
import '../../../core/map/replay_map_types.dart';
import '../../../core/map/replay_route_map.dart';
import '../domain/journey_route.dart';
import 'journey_map_types.dart';
import 'journey_replay_path.dart';

export 'journey_map_types.dart'
    show JourneyLatLng, JourneyMapMoment, JourneyMapMomentKind, JourneyMapPin;

/// Draws a Journey's route segments and pins, framing or following the
/// route. The drawing itself is the shared [ReplayRouteMap]; this adapts a
/// [JourneyRoute] and Journey moments to it.
class JourneyRouteMap extends StatelessWidget {
  const JourneyRouteMap({
    super.key,
    required this.route,
    this.played,
    this.marker,
    this.start,
    this.end,
    this.moments = const [],
    this.currentIndex,
    this.follow = false,
    this.animateFollow = true,
    this.bottomInset = 0,
    this.places,
    this.onPlaceTapped,
    this.onUserPan,
    this.pulsing = false,
  });

  final JourneyRoute route;

  /// During replay: the part already played, drawn in the accent colour on
  /// top of [route]. Null draws [route] in the played colour throughout.
  final JourneyRoute? played;
  final JourneyLatLng? marker;
  final JourneyLatLng? start;
  final JourneyLatLng? end;

  /// Key moments along the route, coloured by whether [currentIndex] has
  /// passed them yet.
  final List<JourneyMapMoment> moments;
  final int? currentIndex;
  final bool follow;

  /// Ease live updates; replay frames jump to the next position.
  final bool animateFollow;

  /// Height covered by controls at the bottom.
  final double bottomInset;

  /// Kaunti47 place pins, as on Home's map; tapping one reports it.
  final Future<List<MapPlace>>? places;
  final ValueChanged<MapPlace>? onPlaceTapped;
  final VoidCallback? onUserPan;

  /// Gently pulses the replay marker while paused at a key moment.
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    final played = this.played;
    return ReplayRouteMap(
      route: JourneyReplayPath(route),
      played: played == null ? null : JourneyReplayPath(played),
      marker: marker,
      start: start,
      end: end,
      moments: [
        for (final moment in moments)
          (
            at: moment.at,
            kind: moment.kind == JourneyMapMomentKind.photo
                ? ReplayMomentKind.photo
                : ReplayMomentKind.note,
            index: moment.index,
          ),
      ],
      currentIndex: currentIndex,
      follow: follow,
      animateFollow: animateFollow,
      bottomInset: bottomInset,
      places: places,
      onPlaceTapped: onPlaceTapped,
      onUserPan: onUserPan,
      pulsing: pulsing,
    );
  }
}
