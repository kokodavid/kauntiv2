import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Mapbox exports its own `Size`; this file means Flutter's.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../core/design/app_type_scale.dart';
import '../../../core/services/app_config_provider.dart';
import '../../../core/services/app_mapbox_telemetry.dart';
import '../../../design/app_colors.dart';
import '../../map_home/application/county_camera_fit.dart';
import '../domain/journey_route.dart';
import 'journey_map_layers.dart';

export 'journey_map_layers.dart' show JourneyLatLng;

/// A Journey's route on the Mapbox map: one line per segment (gaps stay
/// gaps), lone fixes as dots, optional [start] / [end] pins and a [marker]
/// for replay. With [follow] the camera tracks the marker or the newest
/// point (replay, live recording); otherwise it frames the whole route.
class JourneyRouteMap extends ConsumerStatefulWidget {
  const JourneyRouteMap({
    super.key,
    required this.route,
    this.played,
    this.marker,
    this.start,
    this.end,
    this.follow = false,
    this.animateFollow = true,
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
  final bool follow;

  /// Ease the camera to each new point (live) or jump (replay frames come
  /// too fast to animate each one).
  final bool animateFollow;

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
  late final String _token = ref.read(appConfigProvider).mapboxAccessToken;
  Size _size = const Size(360, 240);

  @override
  void initState() {
    super.initState();
    if (_token.isNotEmpty) MapboxOptions.setAccessToken(_token);
  }

  @override
  void didUpdateWidget(JourneyRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      unawaited(_setSource(JourneyMapLayers.endpointSource, _endpointJson()));
    }
    // Leaving replay: frame the whole route again.
    if (oldWidget.follow && !widget.follow) {
      unawaited(_moveCamera(animate: true));
    }
  }

  void _onMapCreated(MapboxMap map) {
    _map = map;
    unawaited(AppMapboxTelemetry.applyPrivacyDefault());
    unawaited(map.scaleBar.updateSettings(ScaleBarSettings(enabled: false)));
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
    await _moveCamera(animate: false);
  }

  String _routeJson() => jsonEncode(widget.route.toGeoJson());

  double get _routeOpacity =>
      widget.played == null ? 1 : JourneyMapLayers.fadedOpacity;

  String _playedJson() {
    final played = widget.played;
    return played == null
        ? JourneyMapLayers.emptyJson
        : jsonEncode(played.toGeoJson());
  }

  String _markerJson() {
    final tip = widget.played?.segments.lastOrNull?.lastOrNull;
    return JourneyMapLayers.markerJson(
      widget.marker,
      tipFrom: tip == null
          ? null
          : (latitude: tip.latitude, longitude: tip.longitude),
    );
  }

  String _endpointJson() =>
      JourneyMapLayers.pointsJson({'start': widget.start, 'end': widget.end});

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

  static CameraOptions _centeredOn(JourneyLatLng at) => CameraOptions(
    center: Point(coordinates: Position(at.longitude, at.latitude)),
    zoom: 15,
  );

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
      final box = (
        minLng: bounds.west,
        minLat: bounds.south,
        maxLng: bounds.east,
        maxLat: bounds.north,
      );
      camera = CameraOptions(
        center: Point(
          coordinates: Position(
            (bounds.west + bounds.east) / 2,
            (bounds.south + bounds.north) / 2,
          ),
        ),
        zoom: CountyCameraFit.zoomToFit(
          box,
          width: _size.width,
          height: math.max(_size.height, 120),
          fill: 0.75,
          minZoom: 4,
          maxZoom: 16,
        ),
      );
    }
    if (animate) {
      await map.easeTo(camera, MapAnimationOptions(duration: 600));
    } else {
      await map.setCamera(camera);
    }
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
        return MapWidget(
          styleUri: MapboxStyles.OUTDOORS,
          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(37.9, 0.2)),
            zoom: 5,
          ),
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: (_) => unawaited(_onStyleLoaded()),
        );
      },
    );
  }
}
