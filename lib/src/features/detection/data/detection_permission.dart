import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

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

  /// Location is switched on for the whole phone. This is separate from
  /// the app's permission, which still reads as granted while it's off.
  /// Can't tell: treat it as on rather than warn by mistake.
  Future<bool> servicesEnabled() async {
    try {
      return await Permission.location.serviceStatus.isEnabled;
    } on Object {
      return true;
    }
  }

  /// Asks the phone to turn location on. Android shows its own dialog; iOS
  /// doesn't let apps do that, so it opens Settings instead.
  Future<void> turnOnServices() async {
    try {
      if (await Location.instance.requestService()) return;
    } on Object {
      // Fall through to Settings.
    }
    await _service.openSettings();
  }

  /// The OS app settings screen, the only way back once "Always" was
  /// taken away there.
  Future<void> openSettings() => _service.openSettings();
}
