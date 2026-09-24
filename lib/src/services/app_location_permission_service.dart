import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_logger.dart';

enum AppLocationPermissionResult {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

class AppLocationPermissionService {
  const AppLocationPermissionService();

  static const _logger = AppLogger.location();
  static const _iosLocationChannel = MethodChannel(
    'com.giglab.kaunti47/location',
  );

  Future<AppLocationPermissionResult> checkStatus() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosCheckStatus();
    }

    final foregroundStatus = await Permission.locationWhenInUse.status;

    if (!foregroundStatus.isGranted) {
      return _mapStatus(foregroundStatus);
    }

    final alwaysStatus = await Permission.locationAlways.status;

    if (alwaysStatus.isGranted || alwaysStatus.isLimited) {
      return AppLocationPermissionResult.granted;
    }

    return _mapStatus(alwaysStatus);
  }

  /// Whether the app may read location while in the foreground ("while
  /// using" or "always"). Used by the real map's "you are here" view, which
  /// needs no background access.
  Future<bool> hasForegroundLocation() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final status = await _iosLocationChannel.invokeMethod<String>(
          'locationAuthorizationStatus',
        );
        return status == 'authorizedAlways' || status == 'authorizedWhenInUse';
      } on PlatformException {
        return false;
      } on MissingPluginException {
        return false;
      }
    }
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted || status.isLimited;
  }

  /// Opens the OS app-settings screen. Android/iOS never re-show the
  /// permission dialog once it has been permanently denied, so this is the
  /// only way for the user to recover without reinstalling the app.
  Future<bool> openSettings() => openAppSettings();

  Future<AppLocationPermissionResult> requestLocationAccess() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosRequestLocationAccess();
    }

    _logger.info('Requesting foreground location permission.');
    final foregroundStatus = await Permission.locationWhenInUse.request();

    if (!foregroundStatus.isGranted) {
      _logger.warning(
        'Foreground location permission was ${foregroundStatus.name}.',
      );
      return _mapStatus(foregroundStatus);
    }

    _logger.info('Foreground location permission granted.');
    _logger.info('Requesting always/background location permission.');
    final alwaysStatus = await Permission.locationAlways.request();

    if (alwaysStatus.isGranted || alwaysStatus.isLimited) {
      _logger.info('Always/background location permission granted.');
      return AppLocationPermissionResult.granted;
    }

    _logger.warning(
      'Always/background location permission was ${alwaysStatus.name}.',
    );

    return _mapStatus(alwaysStatus);
  }

  AppLocationPermissionResult _mapStatus(PermissionStatus status) {
    if (status.isPermanentlyDenied) {
      return AppLocationPermissionResult.permanentlyDenied;
    }
    if (status.isRestricted) {
      return AppLocationPermissionResult.restricted;
    }
    return AppLocationPermissionResult.denied;
  }

  Future<AppLocationPermissionResult> _iosCheckStatus() async {
    try {
      final status = await _iosLocationChannel.invokeMethod<String>(
        'locationAuthorizationStatus',
      );
      return _mapNativeIosStatus(status);
    } on PlatformException catch (error) {
      _logger.warning(
        'iOS location authorization status failed: ${error.code}.',
      );
      return AppLocationPermissionResult.denied;
    } on MissingPluginException {
      _logger.warning('iOS location authorization channel is not registered.');
      return AppLocationPermissionResult.denied;
    }
  }

  Future<AppLocationPermissionResult> _iosRequestLocationAccess() async {
    _logger.info('Requesting iOS always/background location permission.');
    try {
      final status = await _iosLocationChannel.invokeMethod<String>(
        'requestAlwaysLocationAuthorization',
      );
      final result = _mapNativeIosStatus(status);
      if (result == AppLocationPermissionResult.granted) {
        _logger.info('iOS always/background location permission granted.');
      } else {
        _logger.warning(
          'iOS always/background location permission was ${status ?? 'unknown'}.',
        );
      }
      return result;
    } on PlatformException catch (error) {
      _logger.warning(
        'iOS always/background location permission failed: ${error.code}.',
      );
      return AppLocationPermissionResult.denied;
    } on MissingPluginException {
      _logger.warning('iOS location authorization channel is not registered.');
      return AppLocationPermissionResult.denied;
    }
  }

  AppLocationPermissionResult _mapNativeIosStatus(String? status) {
    return switch (status) {
      'authorizedAlways' => AppLocationPermissionResult.granted,
      'authorizedWhenInUse' => AppLocationPermissionResult.permanentlyDenied,
      'restricted' => AppLocationPermissionResult.restricted,
      'denied' => AppLocationPermissionResult.permanentlyDenied,
      'notDetermined' => AppLocationPermissionResult.denied,
      _ => AppLocationPermissionResult.denied,
    };
  }
}
