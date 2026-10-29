import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Mapbox exports its own `Size`; this file means Flutter's.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../core/services/app_config_provider.dart';
import '../../../core/services/app_mapbox_telemetry.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../../map_home/application/county_camera_fit.dart';
import '../domain/plan_route.dart';
import 'plan_map_layers.dart';
import 'plan_screen_states.dart';

/// The plan's days on a live Mapbox map. [activeDay] draws that day solid
/// and frames it; null shows every day. Touches belong to the map.
class PlanMap extends ConsumerStatefulWidget {
  const PlanMap({
    super.key,
    required this.days,
    this.activeDay,
    this.padding = const EdgeInsets.all(24),
  });

  final List<PlanMapDay> days;
  final int? activeDay;
  final EdgeInsets padding;

  @override
  ConsumerState<PlanMap> createState() => _PlanMapState();
}

class _PlanMapState extends ConsumerState<PlanMap> {
  late final String _token = ref.read(appConfigProvider).mapboxAccessToken;

  MapboxMap? _map;
  Size _size = Size.zero;
  bool _styled = false;
  bool _loading = true;
  bool _failed = false;
  int _attempt = 0;
  Timer? _watch;
  String _linesShown = '';
  String _pinsShown = '';

  List<PlanRoutePoint> _framed() {
    final active = widget.activeDay;
    final days = active == null
        ? widget.days
        : widget.days.where((d) => d.number == active).toList();
    final shown = days.isEmpty ? widget.days : days;
    return [
      for (final day in shown) ...day.line,
      for (final day in shown) ...day.stops,
    ];
  }

  @override
  void initState() {
    super.initState();
    if (_token.isNotEmpty) {
      MapboxOptions.setAccessToken(_token);
      _startWatch();
    }
  }

  @override
  void didUpdateWidget(PlanMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_styled) {
      unawaited(
        _refresh(reframe: oldWidget.activeDay != widget.activeDay),
      );
    }
  }

  @override
  void dispose() {
    _watch?.cancel();
    super.dispose();
  }

  void _startWatch() {
    _watch?.cancel();
    _watch = Timer(const Duration(seconds: 12), _fail);
  }

  void _fail() {
    _watch?.cancel();
    if (mounted) {
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _retry() {
    setState(() {
      _failed = false;
      _loading = true;
      _styled = false;
      _attempt++;
    });
    _startWatch();
  }

  CameraOptions _camera(List<PlanRoutePoint> points) {
    var minLng = double.infinity, minLat = double.infinity;
    var maxLng = -double.infinity, maxLat = -double.infinity;
    for (final p in points) {
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
    }
    final bounds = (
      minLng: minLng,
      minLat: minLat,
      maxLng: maxLng,
      maxLat: maxLat,
    );
    final center = CountyCameraFit.centerOf(bounds);
    final pad = widget.padding;
    final zoom = points.length < 2
        ? 11.0
        : CountyCameraFit.zoomToFit(
            bounds,
            width: (_size.width - pad.horizontal)
                .clamp(80.0, 4000.0)
                .toDouble(),
            height: (_size.height - pad.vertical)
                .clamp(80.0, 4000.0)
                .toDouble(),
            fill: 0.9,
            minZoom: 4,
            maxZoom: 15,
          );
    return CameraOptions(
      center: Point(coordinates: Position(center.lng, center.lat)),
      zoom: zoom,
    );
  }

  Future<void> _refresh({required bool reframe}) async {
    final map = _map;
    if (map == null) return;
    final lines = PlanMapLayers.linesJson(widget.days, widget.activeDay);
    final pins = PlanMapLayers.pinsJson(widget.days, widget.activeDay);
    if (lines != _linesShown) {
      _linesShown = lines;
      await map.style.setStyleSourceProperty(
        PlanMapLayers.lineSource,
        'data',
        lines,
      );
    }
    if (pins != _pinsShown) {
      _pinsShown = pins;
      await map.style.setStyleSourceProperty(
        PlanMapLayers.pinSource,
        'data',
        pins,
      );
    }
    final points = _framed();
    if (reframe && points.isNotEmpty) {
      await map.easeTo(_camera(points), MapAnimationOptions(duration: 400));
    }
  }

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null) return;
    try {
      _linesShown = PlanMapLayers.linesJson(widget.days, widget.activeDay);
      _pinsShown = PlanMapLayers.pinsJson(widget.days, widget.activeDay);
      await PlanMapLayers.add(map, lines: _linesShown, pins: _pinsShown);
      _styled = true;
      final points = _framed();
      if (points.isNotEmpty) await map.setCamera(_camera(points));
      _watch?.cancel();
      if (mounted) setState(() => _loading = false);
    } on Object {
      _fail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = _framed();
    if (_token.isEmpty || points.isEmpty) {
      return const PlanMapNote(
        icon: Icons.map_outlined,
        title: 'No map yet',
        message: 'Add places and their roads appear here.',
      );
    }
    if (_failed) {
      return PlanMapNote(
        icon: Icons.map_outlined,
        title: "Couldn't load the map",
        message: 'Check your connection and try again.',
        onRetry: _retry,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : 360,
          constraints.hasBoundedHeight ? constraints.maxHeight : 240,
        );
        final camera = _camera(points);
        return Stack(
          fit: StackFit.expand,
          children: [
            MapWidget(
              key: ValueKey('plan-map-$_attempt'),
              styleUri: MapboxStyles.OUTDOORS,
              textureView: true,
              // ignore: experimental_member_use
              androidHostingMode: AndroidPlatformViewHostingMode.TLHC_HC,
              viewport: CameraViewportState(
                center: camera.center,
                zoom: camera.zoom,
              ),
              gestureRecognizers: {
                const Factory<OneSequenceGestureRecognizer>(
                  EagerGestureRecognizer.new,
                ),
              },
              onMapCreated: (map) {
                _map = map;
                _styled = false;
                unawaited(AppMapboxTelemetry.applyPrivacyDefault());
                unawaited(
                  map.scaleBar.updateSettings(ScaleBarSettings(enabled: false)),
                );
              },
              onStyleLoadedListener: (_) => unawaited(_onStyleLoaded()),
              onMapLoadErrorListener: (event) {
                if (event.type == MapLoadErrorType.STYLE) _fail();
              },
            ),
            if (_loading)
              const ColoredBox(
                color: AppColors.lockedFill,
                child: Center(
                  child: AppProgressIndicator(
                    color: AppColors.accent,
                    radius: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
