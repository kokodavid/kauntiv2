import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../design/app_colors.dart';
import '../application/county_camera_fit.dart';
import '../application/real_map_start_focus.dart';

/// Where the real map looks: the user's own surroundings by default, their
/// home county when location isn't available, and the whole of Kenya only
/// as the starting frame the camera flies in from.
///
/// Location is read once per focus (and shown by Mapbox's dot) while this
/// screen is open, never stored (doc 05: precise location is
/// foreground-only).
abstract final class RealMapFocus {
  /// Close enough to see nearby places as photo markers; zooming out past
  /// `RealMapLayers.markerMinZoom` turns them back into the Kenya-wide dots.
  static const localZoom = 8.5;

  static CameraViewportState kenya(double pitch) => CameraViewportState(
    center: Point(coordinates: Position(37.9, 0.3)),
    zoom: 5.1,
    pitch: pitch,
  );

  /// The camera for the decided opening focus: the user's own position,
  /// else their home county, both at local zoom; else all of Kenya.
  static CameraViewportState viewportFor(
    RealMapStartFocus focus,
    double pitch,
  ) => switch (focus) {
    FocusOnUser(:final latitude, :final longitude) => _at(
      longitude,
      latitude,
      localZoom,
      pitch,
    ),
    FocusOnHomeCounty(:final bounds) => _at(
      CountyCameraFit.centerOf(bounds).lng,
      CountyCameraFit.centerOf(bounds).lat,
      localZoom - 0.5,
      pitch,
    ),
    FocusOnKenya() => kenya(pitch),
  };

  static CameraViewportState _at(
    double lng,
    double lat,
    double zoom,
    double pitch,
  ) => CameraViewportState(
    center: Point(coordinates: Position(lng, lat)),
    zoom: zoom,
    pitch: pitch,
  );

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
