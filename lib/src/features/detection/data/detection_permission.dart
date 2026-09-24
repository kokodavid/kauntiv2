import '../../../services/app_location_permission_service.dart';

/// The OS permission automatic detection needs: background location
/// ("Allow all the time" on Android, "Always" on iOS). Without it the OS
/// geofences can't wake the app, so detection pauses (v1 showed Home's
/// manual mode for the same case).
class DetectionPermission {
  const DetectionPermission([
    this._service = const AppLocationPermissionService(),
  ]);

  final AppLocationPermissionService _service;

  Future<bool> backgroundGranted() async {
    try {
      return await _service.checkStatus() ==
          AppLocationPermissionResult.granted;
    } on Object {
      // Can't tell: keep detection running rather than pausing on a
      // platform hiccup. A real loss shows on the next check.
      return true;
    }
  }

  /// The OS app settings screen, the only way back once "Always" was
  /// taken away there.
  Future<void> openSettings() => _service.openSettings();
}
