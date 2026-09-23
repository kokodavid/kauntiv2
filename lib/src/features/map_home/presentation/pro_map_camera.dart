import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
// Mapbox exports its own `Size`; this file means Flutter's.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../application/county_camera_fit.dart';

/// Camera moves for the Pro map: flying into a county so it's framed above
/// the peek sheet, and releasing the sheet padding afterwards.
abstract final class ProMapCamera {
  static const flightDuration = Duration(milliseconds: 1400);

  static Future<void> flyToCounty(
    MapboxMap map,
    CountyBounds bounds, {
    required Size screen,
    required double pitch,
    // Share of [screen] the peek sheet covers, kept clear when framing.
    double sheetShare = 0.45,
    // Height covered from the top (Home's header over the map).
    double topPadding = 0,
  }) async {
    final bottomPadding = screen.height * sheetShare;
    final center = CountyCameraFit.centerOf(bounds);
    final zoom = CountyCameraFit.zoomToFit(
      bounds,
      width: screen.width,
      // Header above and sheet below can leave a thin band; keep a floor.
      height: math.max(screen.height - bottomPadding - topPadding, 160),
      // Tilted views foreshorten the far side; leave extra room.
      fill: pitch > 0 ? 0.7 : 0.8,
    );
    await map.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(center.lng, center.lat)),
        zoom: zoom,
        pitch: pitch,
        bearing: 0,
        padding: MbxEdgeInsets(
          top: topPadding,
          left: 0,
          bottom: bottomPadding,
          right: 0,
        ),
      ),
      MapAnimationOptions(duration: flightDuration.inMilliseconds),
    );
  }

  /// Eases the camera to [pitch] (3D toggle).
  static void tiltTo(MapboxMap map, double pitch) {
    unawaited(
      map.easeTo(
        CameraOptions(pitch: pitch),
        MapAnimationOptions(duration: 800),
      ),
    );
  }

  /// Drops the sheet padding so the county eases back to screen centre.
  static void releaseSheetPadding(MapboxMap map) {
    unawaited(
      map.easeTo(
        CameraOptions(
          padding: MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        ),
        MapAnimationOptions(duration: 500),
      ),
    );
  }
}
