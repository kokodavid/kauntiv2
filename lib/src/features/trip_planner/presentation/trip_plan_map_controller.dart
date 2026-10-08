import 'dart:async';
import 'dart:ui';

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../map_home/application/county_camera_fit.dart';
import '../domain/trip_route.dart';

/// Moves the camera of a [TripPlanMap] from outside it: fit the road
/// above a card, zoom to a stop, and say where a point is on screen.
class TripPlanMapController {
  MapboxMap? _map;
  Size _size = Size.zero;

  /// Called whenever the camera moves, so overlays can follow it.
  VoidCallback? onCameraChanged;

  /// The map, once the style is loaded; false before that.
  bool get attached => _map != null;

  // ignore: use_setters_to_change_properties
  void attach(MapboxMap map, Size size) {
    _map = map;
    _size = size;
  }

  void detach() => _map = null;

  void resize(Size size) => _size = size;

  /// The camera that shows [points] with [padding] kept clear.
  static CameraOptions framing(
    List<TripRoutePoint> points, {
    required Size size,
    required EdgeInsets padding,
    double fill = 0.9,
  }) {
    var minLng = double.infinity, minLat = double.infinity;
    var maxLng = -double.infinity, maxLat = -double.infinity;
    for (final p in points) {
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
    }
    final bounds = (
      minLng: minLng,
      minLat: minLat,
      maxLng: maxLng,
      maxLat: maxLat,
    );
    final center = CountyCameraFit.centerOf(bounds);
    final zoom = points.length < 2
        ? 11.0
        : CountyCameraFit.zoomToFit(
            bounds,
            width: (size.width - padding.horizontal).clamp(80.0, 4000.0).toDouble(),
            height: (size.height - padding.vertical).clamp(80.0, 4000.0).toDouble(),
            fill: fill,
            minZoom: 4,
            maxZoom: 16,
          );
    return CameraOptions(
      center: Point(coordinates: Position(center.lng, center.lat)),
      zoom: zoom,
      padding: MbxEdgeInsets(
        top: padding.top,
        left: padding.left,
        bottom: padding.bottom,
        right: padding.right,
      ),
    );
  }

  Future<void> fit(
    List<TripRoutePoint> points, {
    required EdgeInsets padding,
    bool animate = true,
  }) async {
    final map = _map;
    if (map == null || points.isEmpty) return;
    final camera = framing(points, size: _size, padding: padding);
    if (animate) {
      await map.easeTo(camera, MapAnimationOptions(duration: 400));
    } else {
      await map.setCamera(camera);
    }
  }

  /// Centres [point] in the area [padding] leaves clear, close in.
  Future<void> focus(
    TripRoutePoint point, {
    required EdgeInsets padding,
    double zoom = 12,
  }) async {
    final map = _map;
    if (map == null) return;
    await map.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(point.lng, point.lat)),
        zoom: zoom,
        padding: MbxEdgeInsets(
          top: padding.top,
          left: padding.left,
          bottom: padding.bottom,
          right: padding.right,
        ),
      ),
      MapAnimationOptions(duration: 500),
    );
  }

  /// Where [point] is on the map widget, in logical pixels.
  Future<Offset?> pixelFor(TripRoutePoint point) async {
    final map = _map;
    if (map == null) return null;
    final px = await map.pixelForCoordinate(
      Point(coordinates: Position(point.lng, point.lat)),
    );
    return Offset(px.x, px.y);
  }
}
