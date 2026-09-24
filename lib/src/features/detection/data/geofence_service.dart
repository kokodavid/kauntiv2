import 'package:native_geofence/native_geofence.dart';

import '../../../counties/county_paths.dart';
import '../../../services/app_logger.dart';
import 'geofence_callback.dart';

/// OS-level county geofences (ported from v1). One circle per county
/// (centroid + radius); only the current county and its neighbours are
/// registered, because iOS caps an app at 20 monitored regions. The
/// circles only wake the app: the polygon lookup in the callback decides
/// which county the phone is really in.
class GeofenceService {
  GeofenceService();

  static const _logger = AppLogger.detection();

  bool _initialized = false;
  Set<int>? _lastWindow;

  /// Must run on every cold start before any other geofence call.
  Future<void> initialize() async {
    if (_initialized) return;
    await NativeGeofenceManager.instance.initialize();
    _initialized = true;
  }

  /// The geofence window for [countyCode]: it plus its neighbours.
  static Set<int> windowFor(int countyCode) => {
    countyCode,
    ...CountyPaths.neighborCodes[countyCode] ?? const <int>[],
  };

  /// Registers [countyCode]'s window, removing geofences outside it and
  /// adding missing ones. [triggerEnterImmediately] makes the OS report an
  /// ENTER for a geofence the phone is already inside (first run).
  Future<void> registerWindowFor(
    int countyCode, {
    bool triggerEnterImmediately = false,
  }) async {
    final window = windowFor(countyCode);
    final last = _lastWindow;
    if (!triggerEnterImmediately &&
        last != null &&
        last.length == window.length &&
        window.every(last.contains)) {
      return;
    }

    final manager = NativeGeofenceManager.instance;
    final registeredIds = await manager.getRegisteredGeofenceIds();
    final registered = registeredIds.map(int.tryParse).whereType<int>().toSet();
    for (final id in registeredIds) {
      final code = int.tryParse(id);
      if (code == null || !window.contains(code)) {
        await manager.removeGeofenceById(id);
      }
    }

    final added = <int>[];
    for (final code in window) {
      if (registered.contains(code)) continue;
      final centroid = CountyPaths.centroids[code];
      final radius = CountyPaths.geofenceRadiusMeters[code];
      if (centroid == null || radius == null) continue;
      await manager.createGeofence(
        Geofence(
          id: '$code',
          location: Location(latitude: centroid.$1, longitude: centroid.$2),
          radiusMeters: radius.toDouble(),
          triggers: const {GeofenceEvent.enter, GeofenceEvent.exit},
          iosSettings: IosGeofenceSettings(
            initialTrigger: triggerEnterImmediately,
          ),
          androidSettings: AndroidGeofenceSettings(
            initialTriggers: triggerEnterImmediately
                ? const {GeofenceEvent.enter}
                : const {},
          ),
        ),
        geofenceCallbackDispatcher,
      );
      added.add(code);
    }
    _lastWindow = window;
    _logger.info(
      'Geofence window for county $countyCode: $window (added $added).',
    );
  }

  /// Sign-out or permission loss: stop monitoring everything.
  Future<void> removeAll() async {
    await NativeGeofenceManager.instance.removeAllGeofences();
    _lastWindow = null;
  }
}
