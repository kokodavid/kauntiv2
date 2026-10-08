import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Mapbox exports its own `Size`; this file means Flutter's.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../core/services/app_config_provider.dart';
import '../../../core/services/app_mapbox_telemetry.dart';
import '../domain/trip_route.dart';
import 'trip_plan_map_controller.dart';
import 'trip_plan_map_layers.dart';
import 'trip_plan_map_surface.dart';

/// The planned road on a live Mapbox map the user can pan and zoom. It
/// takes its own touches, so dragging it moves the map, not the page.
///
/// [points] with fewer than two entries draws just the place; [dashed]
/// draws the straight line used when the road could not be planned.
class TripPlanMap extends ConsumerStatefulWidget {
  const TripPlanMap({
    super.key,
    required this.points,
    this.stops = const [],
    this.dashed = false,
    this.selected,
    this.controller,
    this.onMarkerTap,
    this.padding = EdgeInsets.zero,
    this.height = defaultHeight,
    this.rounded = true,
  });

  final List<TripRoutePoint> points;

  /// Planned stops along the way, numbered in driving order.
  final List<TripRoutePoint> stops;
  final bool dashed;

  /// Index into [TripPlanMapLayers.markers] drawn bigger with a halo.
  final int? selected;
  final TripPlanMapController? controller;

  /// A pin was tapped; the index is into [TripPlanMapLayers.markers].
  final ValueChanged<int>? onMarkerTap;

  /// Space the first camera keeps clear (the full-screen map's card).
  final EdgeInsets padding;

  /// Null fills the space it is given (the full-screen map).
  final double? height;
  final bool rounded;

  static const defaultHeight = 208.0;

  @override
  ConsumerState<TripPlanMap> createState() => _TripPlanMapState();
}

class _TripPlanMapState extends ConsumerState<TripPlanMap> {
  late final String _token = ref.read(appConfigProvider).mapboxAccessToken;
  late final TripPlanMapController _fallback = TripPlanMapController();

  MapboxMap? _map;
  bool _styled = false;
  bool _loading = true;
  bool _failed = false;
  int _attempt = 0;
  Timer? _loadWatch;
  String _routeShown = '';
  String _markersShown = '';

  TripPlanMapController get _controller => widget.controller ?? _fallback;

  List<TripRoutePoint> get _markers =>
      TripPlanMapLayers.markers(widget.points, widget.stops);
  String get _routeJson => TripPlanMapLayers.routeJson(widget.points);
  String get _markersJson =>
      TripPlanMapLayers.markersJson(_markers, widget.selected);

  @override
  void initState() {
    super.initState();
    if (_token.isNotEmpty) {
      MapboxOptions.setAccessToken(_token);
      _startLoadWatch();
    }
  }

  @override
  void didUpdateWidget(TripPlanMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_styled) unawaited(_refresh());
  }

  @override
  void dispose() {
    _loadWatch?.cancel();
    _controller.detach();
    super.dispose();
  }

  void _startLoadWatch() {
    _loadWatch?.cancel();
    _loadWatch = Timer(const Duration(seconds: 12), _fail);
  }

  void _ready() {
    _loadWatch?.cancel();
    if (mounted) setState(() => _loading = false);
  }

  void _fail() {
    _loadWatch?.cancel();
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
      _routeShown = '';
      _markersShown = '';
      _attempt++;
    });
    _startLoadWatch();
  }

  /// New route or pins: update the sources in place, so the map is not
  /// rebuilt (and does not flash) for every change.
  Future<void> _refresh() async {
    final map = _map;
    if (map == null) return;
    final route = _routeJson;
    final markers = _markersJson;
    if (route != _routeShown) {
      _routeShown = route;
      await map.style.setStyleSourceProperty(
        TripPlanMapLayers.routeSource,
        'data',
        route,
      );
    }
    if (markers != _markersShown) {
      _markersShown = markers;
      await map.style.setStyleSourceProperty(
        TripPlanMapLayers.markerSource,
        'data',
        markers,
      );
    }
  }

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null) return;
    try {
      _routeShown = _routeJson;
      _markersShown = _markersJson;
      await TripPlanMapLayers.add(
        map,
        route: _routeShown,
        markers: _markersShown,
        dashed: widget.dashed,
        hasRoute: widget.points.length > 1,
      );
      _styled = true;
      await _controller.fit(
        widget.points,
        padding: widget.padding,
        animate: false,
      );
      _ready();
    } on Object {
      _fail();
    }
  }

  Future<void> _onTap(MapContentGestureContext tap) async {
    final onTap = widget.onMarkerTap;
    if (onTap == null) return;
    final markers = _markers;
    var nearest = -1;
    var best = 36.0;
    for (var i = 0; i < markers.length; i++) {
      final at = await _controller.pixelFor(markers[i]);
      if (at == null) continue;
      final d = (at - Offset(tap.touchPosition.x, tap.touchPosition.y))
          .distance;
      if (d < best) {
        best = d;
        nearest = i;
      }
    }
    if (nearest >= 0) onTap(nearest);
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.rounded ? BorderRadius.circular(20) : BorderRadius.zero;
    if (_token.isEmpty || widget.points.isEmpty) {
      return TripPlanMapUnavailable(
        borderRadius: box,
        height: widget.height,
      );
    }
    if (_failed) return TripPlanMapFailure(onRetry: _retry);
    final mode = widget.points.length < 2
        ? 'pin'
        : widget.dashed
        ? 'dashed'
        : 'road';
    final map = LayoutBuilder(
          builder: (context, constraints) {
            // The whole-screen map is laid out against the screen, never a
            // box that has not settled yet.
            final screen = MediaQuery.sizeOf(context);
            final size = Size(
              constraints.hasBoundedWidth && constraints.maxWidth > 0
                  ? constraints.maxWidth
                  : screen.width,
              constraints.hasBoundedHeight && constraints.maxHeight > 0
                  ? constraints.maxHeight
                  : screen.height,
            );
            _controller.resize(size);
            final camera = TripPlanMapController.framing(
              widget.points,
              size: size,
              padding: widget.padding,
              fill: widget.padding == EdgeInsets.zero ? 0.7 : 0.9,
            );
            return MapWidget(
              key: ValueKey('$mode-$_attempt'),
              styleUri: MapboxStyles.OUTDOORS,
              // Virtual Display can place a newly pushed native map above
              // Flutter's full-screen controls on Android. Texture Layer
              // Hybrid Composition keeps the layers in the expected order.
              textureView: true,
              // ignore: experimental_member_use
              androidHostingMode: AndroidPlatformViewHostingMode.TLHC_HC,
              viewport: CameraViewportState(
                center: camera.center,
                zoom: camera.zoom,
                padding: widget.padding,
              ),
              gestureRecognizers: {
                const Factory<OneSequenceGestureRecognizer>(
                  EagerGestureRecognizer.new,
                ),
              },
              onMapCreated: (map) {
                _map = map;
                _styled = false;
                _controller.attach(map, size);
                map.addInteraction(
                  TapInteraction.onMap((tap) => unawaited(_onTap(tap))),
                  interactionID: 'plan-marker-tap',
                );
                unawaited(AppMapboxTelemetry.applyPrivacyDefault());
                unawaited(
                  map.scaleBar.updateSettings(ScaleBarSettings(enabled: false)),
                );
              },
              onStyleLoadedListener: (_) => unawaited(_onStyleLoaded()),
              onMapLoadErrorListener: (event) {
                if (event.type == MapLoadErrorType.STYLE) _fail();
              },
              onCameraChangeListener: (_) =>
                  _controller.onCameraChanged?.call(),
            );
          },
        );
    return TripPlanMapSurface(
      map: map,
      loading: _loading,
      rounded: widget.rounded,
      borderRadius: box,
      height: widget.height,
    );
  }
}
