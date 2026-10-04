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
import '../domain/public_trip_owner_view.dart';
import '../domain/public_trip_view.dart';

/// A public trip's route on the real map: the trimmed route, its approved
/// start, and the moments and photos the owner chose. Read-only; it never
/// asks for the viewer's location and draws nothing live.
class PublicTripMap extends ConsumerStatefulWidget {
  const PublicTripMap({super.key, required this.trip});

  final PublicTripView trip;

  @override
  ConsumerState<PublicTripMap> createState() => _PublicTripMapState();
}

class _PublicTripMapState extends ConsumerState<PublicTripMap> {
  static const _routeSource = 'public-trip-route';
  static const _pinSource = 'public-trip-pins';

  MapboxMap? _map;
  late final String _token = ref.read(appConfigProvider).mapboxAccessToken;
  Size _size = const Size(360, 280);

  @override
  void initState() {
    super.initState();
    if (_token.isNotEmpty) MapboxOptions.setAccessToken(_token);
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
          viewport: _initialViewport(),
          onMapCreated: (map) {
            _map = map;
            unawaited(AppMapboxTelemetry.applyPrivacyDefault());
            unawaited(map.scaleBar.updateSettings(ScaleBarSettings(enabled: false)));
          },
          onStyleLoadedListener: (_) => unawaited(_addLayers()),
        );
      },
    );
  }

  CameraViewportState _initialViewport() {
    final bounds = _bounds();
    if (bounds == null) {
      return CameraViewportState(
        center: Point(coordinates: Position(37.9, 0.2)),
        zoom: 5,
      );
    }
    return CameraViewportState(
      center: Point(
        coordinates: Position(
          (bounds.minLng + bounds.maxLng) / 2,
          (bounds.minLat + bounds.maxLat) / 2,
        ),
      ),
      zoom: CountyCameraFit.zoomToFit(
        bounds,
        width: _size.width,
        height: _size.height,
        fill: 0.7,
        minZoom: 4,
        maxZoom: 16,
      ),
    );
  }

  CountyBounds? _bounds() {
    var minLng = double.infinity, minLat = double.infinity;
    var maxLng = -double.infinity, maxLat = -double.infinity;
    for (final line in widget.trip.routeLines) {
      for (final point in line) {
        minLng = math.min(minLng, point.longitude);
        maxLng = math.max(maxLng, point.longitude);
        minLat = math.min(minLat, point.latitude);
        maxLat = math.max(maxLat, point.latitude);
      }
    }
    if (minLng > maxLng) return null;
    return (minLng: minLng, minLat: minLat, maxLng: maxLng, maxLat: maxLat);
  }

  Future<void> _addLayers() async {
    final style = _map?.style;
    if (style == null) return;
    await style.addSource(GeoJsonSource(id: _routeSource, data: _routeJson()));
    await style.addSource(GeoJsonSource(id: _pinSource, data: _pinJson()));
    await style.addLayer(
      LineLayer(
        id: 'public-trip-line',
        sourceId: _routeSource,
        lineColor: AppColors.accent.toARGB32(),
        lineWidth: 4.5,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ),
    );
    await style.addLayer(
      CircleLayer(
        id: 'public-trip-pins',
        sourceId: _pinSource,
        circleColorExpression: [
          'match',
          ['get', 'kind'],
          'start',
          _hex(AppColors.accent),
          'photo',
          _hex(AppColors.accent),
          _hex(Colors.white),
        ],
        circleStrokeColorExpression: [
          'match',
          ['get', 'kind'],
          'moment',
          _hex(AppColors.accent),
          _hex(Colors.white),
        ],
        circleRadiusExpression: [
          'match',
          ['get', 'kind'],
          'moment',
          4.5,
          6,
        ],
        circleStrokeWidth: 2,
      ),
    );
  }

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  /// The route as separate lines: a recording break is a real gap, never
  /// joined up.
  String _routeJson() => jsonEncode({
    'type': 'Feature',
    'properties': const <String, Object>{},
    'geometry': {
      'type': 'MultiLineString',
      'coordinates': [
        for (final line in widget.trip.routeLines)
          if (line.length > 1)
            [
              for (final point in line) [point.longitude, point.latitude],
            ],
      ],
    },
  });

  String _pinJson() {
    Map<String, Object> pin(String kind, double lat, double lng) => {
      'type': 'Feature',
      'properties': {'kind': kind},
      'geometry': {
        'type': 'Point',
        'coordinates': [lng, lat],
      },
    };
    final start = widget.trip.publicStart;
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        for (final PublicTripMoment moment in widget.trip.moments)
          pin('moment', moment.latitude, moment.longitude),
        for (final photo in widget.trip.photos)
          if (photo.hasPlace) pin('photo', photo.latitude!, photo.longitude!),
        if (start != null) pin('start', start.latitude, start.longitude),
      ],
    });
  }
}
