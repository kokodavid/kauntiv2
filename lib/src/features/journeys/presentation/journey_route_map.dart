import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Mapbox exports its own `Size`; this file means Flutter's.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/map_place.dart';
import '../../../core/map/map_place_layers.dart';
import '../../../core/map/map_places_layer.dart';
import '../../../core/services/app_config_provider.dart';
import '../../../core/services/app_mapbox_telemetry.dart';
import '../../../design/app_colors.dart';
import '../domain/journey_route.dart';
import 'journey_map_layers.dart';

export 'journey_map_layers.dart' show JourneyLatLng, JourneyMapPin;

part 'journey_route_map_helpers.dart';

/// Draws route segments and pins on Mapbox, framing or following the route.
class JourneyRouteMap extends ConsumerStatefulWidget {
  const JourneyRouteMap({
    super.key,
    required this.route,
    this.played,
    this.marker,
    this.start,
    this.end,
    this.pins = const [],
    this.follow = false,
    this.animateFollow = true,
    this.bottomInset = 0,
    this.places,
    this.onPlaceTapped,
    this.onUserPan,
    this.pulsing = false,
  });

  final JourneyRoute route;

  /// During replay: the part already played, drawn on top of a faded
  /// [route], with a short line from its last point to [marker]. Null
  /// draws [route] in full colour.
  final JourneyRoute? played;
  final JourneyLatLng? marker;

  /// Where the Journey began (green) and ended (red).
  final JourneyLatLng? start;
  final JourneyLatLng? end;

  /// Key moments along the route.
  final List<JourneyLatLng> pins;
  final bool follow;

  /// Ease live updates; replay frames jump to the next position.
  final bool animateFollow;

  /// Height covered by controls at the bottom: the camera centres above
  /// it and the Mapbox logo sits over it.
  final double bottomInset;

  /// Kaunti47 place pins, as on Home's map; tapping one reports it.
  final Future<List<MapPlace>>? places;
  final ValueChanged<MapPlace>? onPlaceTapped;

  final VoidCallback? onUserPan;

  /// Gently pulses the replay marker: on while paused at a key moment, off
  /// while playing or showing the whole route.
  final bool pulsing;

  @override
  ConsumerState<JourneyRouteMap> createState() => _JourneyRouteMapState();
}

class _JourneyRouteMapState extends ConsumerState<JourneyRouteMap> {
  /// A marker / camera update still on its way to the native map. Frames
  /// arriving meanwhile only mark it stale, so replay never queues up and
  /// falls behind, yet the last position is always drawn.
  bool _markerInFlight = false;
  bool _markerStale = false;
  MapboxMap? _map;
  bool _styleReady = false;
  Timer? _pulseTimer;
  int _pulseElapsedMs = 0;
  static const _markerBaseRadius = 7.0;
  static const _markerPulseAmplitude = 4.0;
  static const _pulseStepMs = 90;
  static const _pulsePeriodMs = 1200;
  late final String _token = ref.read(appConfigProvider).mapboxAccessToken;
  Size _size = const Size(360, 240);
  late final MapPlacesLayer? _places = widget.places == null
      ? null
      : MapPlacesLayer(widget.places);

  @override
  void initState() {
    super.initState();
    if (_token.isNotEmpty) MapboxOptions.setAccessToken(_token);
  }

  @override
  void didUpdateWidget(JourneyRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulsing != widget.pulsing) _syncPulse();
    if (!_styleReady) return;
    if (oldWidget.route.pointCount != widget.route.pointCount) {
      unawaited(_updateRoute());
    }
    if ((oldWidget.played == null) != (widget.played == null)) {
      unawaited(
        _map?.style.setStyleLayerProperty(
          JourneyMapLayers.routeLine,
          'line-opacity',
          _routeOpacity,
        ),
      );
    }
    if (oldWidget.played?.pointCount != widget.played?.pointCount) {
      unawaited(_setSource(JourneyMapLayers.playedSource, _playedJson()));
    }
    if (oldWidget.marker != widget.marker) unawaited(_updateMarker());
    if (oldWidget.start != widget.start ||
        oldWidget.end != widget.end ||
        !listEquals(oldWidget.pins, widget.pins)) {
      unawaited(_setSource(JourneyMapLayers.endpointSource, _endpointJson()));
    }
    // Leaving replay: frame the whole route; re-centring: back on it.
    if (oldWidget.follow != widget.follow) {
      unawaited(_moveCamera(animate: true));
    }
  }

  void _onMapCreated(MapboxMap map) {
    _map = map;
    unawaited(AppMapboxTelemetry.applyPrivacyDefault());
    unawaited(map.scaleBar.updateSettings(ScaleBarSettings(enabled: false)));
    unawaited(JourneyMapLayers.liftOrnaments(map, widget.bottomInset));
  }

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null) return;
    await JourneyMapLayers.add(
      map.style,
      route: _routeJson(),
      played: _playedJson(),
      marker: _markerJson(),
      endpoints: _endpointJson(),
      routeOpacity: _routeOpacity,
    );
    _styleReady = true;
    if (widget.pulsing) _syncPulse();
    await _moveCamera(animate: false);
    final places = _places;
    if (places == null) return;
    MapPlaceLayers.addTapHandler(map, (id) {
      final place = places.placeFor(id);
      if (place != null) widget.onPlaceTapped?.call(place);
    });
    await places.addTo(map.style);
  }

  Future<void> _setSource(String id, String json) async {
    await _map?.style.setStyleSourceProperty(id, 'data', json);
  }

  Future<void> _updateRoute() async {
    await _setSource(JourneyMapLayers.routeSource, _routeJson());
    await _moveCamera(animate: !widget.follow || widget.animateFollow);
  }

  /// Draws the marker (and tip) where it is now and, when following, puts
  /// the camera on it. Runs about once per screen frame during replay.
  Future<void> _updateMarker() async {
    final map = _map;
    if (map == null) return;
    if (_markerInFlight) {
      _markerStale = true;
      return;
    }
    _markerInFlight = true;
    try {
      do {
        _markerStale = false;
        await _setSource(JourneyMapLayers.markerSource, _markerJson());
        final marker = widget.marker;
        if (widget.follow && marker != null) {
          await map.setCamera(_centeredOn(marker));
        }
      } while (_markerStale && mounted);
    } finally {
      _markerInFlight = false;
    }
  }

  CameraOptions _centeredOn(JourneyLatLng at) => CameraOptions(
    center: Point(coordinates: Position(at.longitude, at.latitude)),
    zoom: 15,
    padding: _padding,
  );

  MbxEdgeInsets get _padding =>
      MbxEdgeInsets(top: 0, left: 0, bottom: widget.bottomInset, right: 0);

  Future<void> _moveCamera({required bool animate}) async {
    final map = _map;
    final bounds = widget.route.bounds;
    if (map == null || bounds == null) return;
    final CameraOptions camera;
    if (widget.follow) {
      // Replay follows the marker; live recording the newest point.
      final last = widget.route.segments.last.last;
      camera = _centeredOn(
        widget.marker ?? (latitude: last.latitude, longitude: last.longitude),
      );
    } else {
      camera = JourneyMapLayers.frame(
        bounds,
        width: _size.width,
        height: math.max(_size.height - widget.bottomInset, 120),
        padding: _padding,
      );
    }
    if (animate) {
      await map.easeTo(camera, MapAnimationOptions(duration: 600));
    } else {
      await map.setCamera(camera);
    }
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_token.isEmpty) {
      return const ColoredBox(
        color: AppColors.lockedFill,
        child: Center(
          child: Text(
            'Map unavailable in this build',
            style: AppTypeScale.small,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        final bounds = widget.route.bounds;
        final CameraOptions initialCamera;
        if (bounds == null) {
          initialCamera = CameraOptions(
            center: Point(coordinates: Position(37.9, 0.2)),
            zoom: 5,
          );
        } else if (widget.follow) {
          final last = widget.route.segments.last.last;
          initialCamera = _centeredOn(
            widget.marker ??
                (latitude: last.latitude, longitude: last.longitude),
          );
        } else {
          initialCamera = JourneyMapLayers.frame(
            bounds,
            width: _size.width,
            height: math.max(_size.height - widget.bottomInset, 120),
            padding: _padding,
          );
        }
        return MapWidget(
          styleUri: MapboxStyles.OUTDOORS,
          viewport: CameraViewportState(
            center: initialCamera.center,
            padding: _viewportPadding(initialCamera.padding),
            zoom: initialCamera.zoom,
            bearing: initialCamera.bearing,
            pitch: initialCamera.pitch,
          ),
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: (_) => unawaited(_onStyleLoaded()),
          onScrollListener: widget.onUserPan == null
              ? null
              : (_) => widget.onUserPan!(),
        );
      },
    );
  }
}
