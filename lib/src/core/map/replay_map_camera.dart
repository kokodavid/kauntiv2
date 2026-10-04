import 'dart:math' as math;

import 'replay_map_types.dart';

/// Web-Mercator zoom that fits [bounds] into a [width] x [height] area with
/// [fill] of it used, clamped to [minZoom]..[maxZoom].
double replayZoomToFit(
  ReplayBounds bounds, {
  required double width,
  required double height,
  double fill = 0.75,
  double minZoom = 4,
  double maxZoom = 16,
}) {
  const tileSize = 512.0;
  final spanLng = math.max(bounds.east - bounds.west, 0.01);
  final spanLat = math.max(bounds.north - bounds.south, 0.01);
  double zoomFor(double pixels, double span) =>
      math.log(360 * pixels * fill / (tileSize * span)) / math.ln2;
  final zoom = math.min(zoomFor(width, spanLng), zoomFor(height, spanLat));
  return zoom.clamp(minZoom, maxZoom);
}
