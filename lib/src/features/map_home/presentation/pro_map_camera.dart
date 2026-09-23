import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../application/county_camera_fit.dart';

/// Camera moves for the Pro map: flying into a county so it's framed above
/// the peek sheet, and releasing the sheet padding afterwards.
abstract final class ProMapCamera {
  static const flightDuration = Duration(milliseconds: 1400);

  /// Share of the screen height the peek sheet covers, kept clear when
  /// framing a county.
  static const _sheetShare = 0.45;

  static Future<void> flyToCounty(
    MapboxMap map,
    CountyBounds bounds, {
    required Size screen,
    required double pitch,
  }) async {
    final bottomPadding = screen.height * _sheetShare;
    final center = CountyCameraFit.centerOf(bounds);
    final zoom = CountyCameraFit.zoomToFit(
      bounds,
      width: screen.width,
      height: screen.height - bottomPadding,
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
          top: 0,
          left: 0,
          bottom: bottomPadding,
          right: 0,
        ),
      ),
      MapAnimationOptions(duration: flightDuration.inMilliseconds),
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
