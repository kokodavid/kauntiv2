import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../design/app_colors.dart';
import '../application/county_camera_fit.dart';

/// Where the real map looks: the user's own surroundings by default, their
/// home county when location isn't available, and the whole of Kenya only
/// as the starting frame the camera flies in from.
///
/// Location is read by the Mapbox location component while this screen is
/// open, never stored (doc 05: precise location is foreground-only).
abstract final class RealMapFocus {
  /// Close enough to see nearby places as photo markers; zooming out past
  /// `RealMapLayers.markerMinZoom` turns them back into the Kenya-wide dots.
  static const localZoom = 8.5;

  static CameraViewportState kenya(double pitch) => CameraViewportState(
    center: Point(coordinates: Position(37.9, 0.3)),
    zoom: 5.1,
    pitch: pitch,
  );

  static FollowPuckViewportState aroundUser(double pitch) =>
      FollowPuckViewportState(
        zoom: localZoom,
        pitch: pitch,
        bearing: FollowPuckViewportStateBearingConstant(0),
      );

  static CameraViewportState aroundHomeCounty(
    CountyBounds bounds,
    double pitch,
  ) {
    final center = CountyCameraFit.centerOf(bounds);
    return CameraViewportState(
      center: Point(coordinates: Position(center.lng, center.lat)),
      zoom: localZoom - 0.5,
      pitch: pitch,
    );
  }

  /// Waits for the follow-puck camera to arrive; false if the camera is
  /// still zoomed out after [timeout], i.e. no location fix came in.
  static Future<bool> reachedUser(
    MapboxMap map, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await Future<void>.delayed(timeout);
    final camera = await map.getCameraState();
    return camera.zoom >= localZoom - 1;
  }

  /// Embedded under Home's sheet, the Mapbox logo and attribution (both
  /// required by Mapbox's terms) would be hidden: lift them above the
  /// sheet's peek, and drop the scale bar, which clashes with the Map / Real
  /// switch.
  static Future<void> placeOrnaments(
    MapboxMap map, {
    required double bottomInset,
  }) async {
    await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await map.logo.updateSettings(LogoSettings(marginBottom: bottomInset));
    await map.attribution.updateSettings(
      AttributionSettings(marginBottom: bottomInset),
    );
  }

  /// Stops the camera wandering far outside Kenya.
  static Future<void> keepInKenya(MapboxMap map) => map.setBounds(
    CameraBoundsOptions(
      bounds: CoordinateBounds(
        southwest: Point(coordinates: Position(33.0, -5.5)),
        northeast: Point(coordinates: Position(42.5, 5.5)),
        infiniteBounds: false,
      ),
      minZoom: 4.3,
    ),
  );

  /// Shows the pulsing "you are here" dot.
  static Future<void> showUserDot(MapboxMap map) {
    return map.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: AppColors.accent.toARGB32(),
        showAccuracyRing: false,
      ),
    );
  }
}
