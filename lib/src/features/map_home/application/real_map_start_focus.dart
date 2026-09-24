import 'county_camera_fit.dart';

/// Where the real map's camera opens, decided once from a single position
/// read (no following afterwards, so nothing can pull the camera later).
sealed class RealMapStartFocus {
  const RealMapStartFocus();

  /// The user's own position, when it's inside Kenya.
  static RealMapStartFocus decide({
    required ({double latitude, double longitude})? location,
    required CountyBounds? homeCounty,
  }) {
    if (location != null &&
        isInKenya(latitude: location.latitude, longitude: location.longitude)) {
      return FocusOnUser(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    }
    if (homeCounty != null) return FocusOnHomeCounty(homeCounty);
    return const FocusOnKenya();
  }

  /// Kenya's bounding box. A fix outside it (a phone abroad, an emulator
  /// left on its default California location) would otherwise be clamped
  /// to the edge of the map's Kenya bounds and open on a random border spot.
  static bool isInKenya({
    required double latitude,
    required double longitude,
  }) =>
      latitude >= -4.8 &&
      latitude <= 5.1 &&
      longitude >= 33.8 &&
      longitude <= 42.0;
}

final class FocusOnUser extends RealMapStartFocus {
  const FocusOnUser({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

final class FocusOnHomeCounty extends RealMapStartFocus {
  const FocusOnHomeCounty(this.bounds);

  final CountyBounds bounds;
}

final class FocusOnKenya extends RealMapStartFocus {
  const FocusOnKenya();
}
