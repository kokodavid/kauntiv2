import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../design/app_colors.dart';
import '../application/county_camera_fit.dart';

/// Where the Pro map looks: the user's own surroundings by default, their
/// home county when location isn't available, and the whole of Kenya only
/// as the starting frame the camera flies in from.
///
/// Location is read by the Mapbox location component while this screen is
/// open, never stored (doc 05: precise location is foreground-only).
abstract final class ProMapFocus {
  /// Close enough to see nearby places as photo markers; zooming out past
  /// `ProMapLayers.markerMinZoom` turns them back into the Kenya-wide dots.
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
