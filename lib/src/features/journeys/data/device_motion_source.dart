import 'package:location/location.dart';

/// One location fix, reduced to what motion sensing needs.
typedef MotionFix = ({DateTime at, double? speed});

/// Foreground-only fixes for motion sensing while Home is open. It never
/// asks for permission and never turns on background mode: with no
/// permission it simply has nothing to report.
class DeviceMotionSource {
  DeviceMotionSource({Location? location})
    : _location = location ?? Location.instance;

  final Location _location;

  /// The fixes, or null when location is off or not allowed. Coarse
  /// accuracy and a small distance filter keep the battery cost low.
  Future<Stream<MotionFix>?> open() async {
    if (!await _location.serviceEnabled()) return null;
    if (await _location.hasPermission() != PermissionStatus.granted) {
      return null;
    }
    await _location.changeSettings(
      accuracy: LocationAccuracy.balanced,
      interval: 3000,
      distanceFilter: 3,
    );
    return _location.onLocationChanged
        .where((data) => (data.accuracy ?? 1000) <= 100 && data.isMock != true)
        .map((data) {
          final raw = data.speed;
          return (
            at: DateTime.now(),
            speed: raw != null && raw.isFinite && raw >= 0 ? raw : null,
          );
        });
  }
}
