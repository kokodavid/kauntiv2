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

/// A position on the map.
typedef JourneyLatLng = ({double latitude, double longitude});

/// A Journey's route on the Mapbox map: one line per segment (gaps stay
/// gaps), lone fixes as dots, optional [start] / [end] pins and a [marker]
/// for replay. With [follow] the camera tracks the newest point (live
/// recording, replay); otherwise it frames the whole route.
class JourneyRouteMap extends ConsumerStatefulWidget {
  const JourneyRouteMap({
    super.key,
    required this.route,
    this.marker,
    this.start,
    this.end,
    this.follow = false,
    this.animateFollow = true,
  });

  final JourneyRoute route;
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
  static const _routeSource = 'journey-route';
  static const _markerSource = 'journey-marker';
  static const _endpointSource = 'journey-endpoints';
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
    if (oldWidget.marker != widget.marker) unawaited(_updateMarker());
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      unawaited(_updateEndpoints());
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
    final style = map.style;
    await style.addSource(GeoJsonSource(id: _routeSource, data: _routeJson()));
    await style.addSource(
      GeoJsonSource(id: _markerSource, data: _markerJson()),
    );
    await style.addSource(
      GeoJsonSource(id: _endpointSource, data: _endpointJson()),
    );
    await style.addLayer(
      LineLayer(
        id: 'journey-route-line',
        sourceId: _routeSource,
        lineColor: AppColors.accent.toARGB32(),
        lineWidth: 4.5,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ),
    );
    await style.addLayer(
      CircleLayer(
        id: 'journey-route-dots',
        sourceId: _routeSource,
        filter: [
          '==',
          ['geometry-type'],
          'Point',
        ],
        circleColor: AppColors.accent.toARGB32(),
        circleRadius: 4,
      ),
    );
    await style.addLayer(
      CircleLayer(
        id: 'journey-endpoints',
        sourceId: _endpointSource,
        circleColorExpression: [
          'match',
          ['get', 'kind'],
          'start',
          AppColors.legendHome.toARGB32(),
          AppColors.danger.toARGB32(),
        ],
        circleRadius: 6,
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 2,
      ),
    );
    await style.addLayer(
      CircleLayer(
        id: 'journey-marker',
        sourceId: _markerSource,
        circleColor: Colors.white.toARGB32(),
        circleRadius: 7,
        circleStrokeColor: AppColors.accent.toARGB32(),
        circleStrokeWidth: 3,
      ),
    );
    _styleReady = true;
    await _moveCamera(animate: false);
  }

  String _routeJson() => jsonEncode(widget.route.toGeoJson());

  String _markerJson() => _pointsJson({'marker': widget.marker});

  String _endpointJson() =>
      _pointsJson({'start': widget.start, 'end': widget.end});

  /// Points as a GeoJSON collection, each tagged with its `kind`.
  static String _pointsJson(Map<String, JourneyLatLng?> points) => jsonEncode({
    'type': 'FeatureCollection',
    'features': [
      for (final MapEntry(key: kind, value: point) in points.entries)
        if (point != null)
          {
            'type': 'Feature',
            'properties': {'kind': kind},
            'geometry': {
              'type': 'Point',
              'coordinates': [point.longitude, point.latitude],
            },
          },
    ],
  });

  Future<void> _updateRoute() async {
    await _map?.style.setStyleSourceProperty(
      _routeSource,
      'data',
      _routeJson(),
    );
    await _moveCamera(animate: !widget.follow || widget.animateFollow);
  }

  Future<void> _updateEndpoints() async {
    await _map?.style.setStyleSourceProperty(
      _endpointSource,
      'data',
      _endpointJson(),
    );
  }

  Future<void> _updateMarker() async {
    await _map?.style.setStyleSourceProperty(
      _markerSource,
      'data',
      _markerJson(),
    );
  }

  Future<void> _moveCamera({required bool animate}) async {
    final map = _map;
    final bounds = widget.route.bounds;
    if (map == null || bounds == null) return;
    final CameraOptions camera;
    if (widget.follow) {
      final last = widget.route.segments.last.last;
      camera = CameraOptions(
        center: Point(coordinates: Position(last.longitude, last.latitude)),
        zoom: 15,
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
