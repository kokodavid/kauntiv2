import 'dart:async';

import 'package:flutter/material.dart';
// Mapbox exports its own `Size`; this file means Flutter's.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../core/services/app_mapbox_telemetry.dart';
import '../../../services/app_location_permission_service.dart';
import '../domain/map_home_models.dart';
import '../domain/map_place.dart';
import 'county_peek_sheet.dart';
import 'map_home_map_overlays.dart';
import 'real_map_camera.dart';
import 'real_map_controls.dart';
import 'real_map_county_source.dart';
import 'real_map_focus.dart';
import 'real_map_layers.dart';
import 'real_map_place_widgets.dart';
import 'real_map_places_layer.dart';

/// Home's default map: the county map on a real Mapbox base map, running
/// edge to edge behind Home's header, sheet and nav. Same badge data and
/// colours as the drawn map; tapping a county flies to it and opens the peek.
///
/// Reports [onReady] once the style and county layers are up, or [onFailed]
/// if they can't load (no signal on a cold start, bad token, timeout), so
/// Home can fall back to the drawn map.
class RealMapView extends StatefulWidget {
  const RealMapView({
    super.key,
    required this.accessToken,
    required this.badges,
    required this.homeCountySlug,
    this.loadPlaces,
    this.topInset = 0,
    this.onReady,
    this.onFailed,
  });

  final String accessToken;
  final List<MapHomeCountyBadge> badges;
  final String? homeCountySlug;

  /// Loads the pins for `places`; null shows counties only.
  final Future<List<MapPlace>> Function()? loadPlaces;

  /// How far down Home's header covers the map; controls and county
  /// framing stay below it.
  final double topInset;

  final VoidCallback? onReady;
  final VoidCallback? onFailed;

  @override
  State<RealMapView> createState() => _RealMapViewState();
}

class _RealMapViewState extends State<RealMapView> {
  static const _loadTimeout = Duration(seconds: 12);

  static const _tiltedPitch = 50.0;

  // Starts on all of Kenya, then flies in to the user (or home county).
  ViewportState _viewport = RealMapFocus.kenya(_tiltedPitch);
  bool _hasLocation = false;

  bool _terrainEnabled = true;

  MapboxMap? _map;
  late final _counties = RealMapCountySource(
    badges: widget.badges,
    homeCountySlug: widget.homeCountySlug,
  );
  bool _ready = false;
  bool _failed = false;
  Timer? _loadTimer;
  RealMapBaseStyle _baseStyle = RealMapBaseStyle.outdoors;
  MapHomeCountyBadge? _selected;
  Size _mapSize = Size.zero;
  late final RealMapPlacesLayer _placesLayer;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(widget.accessToken);
    _placesLayer = RealMapPlacesLayer(widget.loadPlaces?.call());
    unawaited(_focusOnStart());
    _loadTimer = Timer(_loadTimeout, _fail);
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  /// Only failures before the first successful load send Home back to the
  /// drawn map; later hiccups (a style switch offline) don't flip maps.
  void _fail() {
    if (!mounted || _ready || _failed) return;
    _failed = true;
    widget.onFailed?.call();
  }

  double get _pitch => _terrainEnabled ? _tiltedPitch : 0;

  Future<void> _focusOnStart() async {
    _hasLocation = await const AppLocationPermissionService()
        .hasForegroundLocation();
    if (!mounted) return;
    final map = _map;
    if (_hasLocation && map != null) unawaited(RealMapFocus.showUserDot(map));
    await _focusOnUser();
  }

  /// "Locate me": follow the user's dot, or frame the home county when
  /// there's no permission or no fix arrives (e.g. simulator set to None).
  Future<void> _focusOnUser() async {
    if (_hasLocation) {
      final following = RealMapFocus.aroundUser(_pitch);
      setState(() => _viewport = following);
      final map = _map;
      if (map == null || await RealMapFocus.reachedUser(map)) return;
      if (!mounted || _viewport != following) return;
    }
    await _counties.geoJson();
    final home = widget.badges
        .where((badge) => badge.county.slug == widget.homeCountySlug)
        .firstOrNull;
    final bounds = _counties.boundsFor(home?.county.code);
    if (!mounted || bounds == null) return;
    setState(() => _viewport = RealMapFocus.aroundHomeCounty(bounds, _pitch));
  }

  void _onMapCreated(MapboxMap map) {
    _map = map;
    unawaited(AppMapboxTelemetry.applyPrivacyDefault());
    if (_hasLocation) unawaited(RealMapFocus.showUserDot(map));
    unawaited(
      RealMapFocus.placeOrnaments(
        map,
        bottomInset: MediaQuery.sizeOf(context).height * 0.16,
      ),
    );
    unawaited(RealMapFocus.keepInKenya(map));
    RealMapLayers.addTapHandlers(
      map,
      onCounty: _onCountyTapped,
      onPlace: _onPlaceTapped,
    );
  }

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null) return;
    final geoJson = await _counties.geoJson();
    await RealMapLayers.addTerrainTo(map.style, enabled: _terrainEnabled);
    await RealMapLayers.addTo(map.style, geoJson);
    await _applyHighlight();
    if (!_ready && !_failed && mounted) {
      _ready = true;
      _loadTimer?.cancel();
      widget.onReady?.call();
    }
    await _addPlaces(map);
  }

  Future<void> _addPlaces(MapboxMap map) async {
    final loaded = await _placesLayer.addTo(map.style);
    if (loaded || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Couldn't load places.")));
  }

  void _onPlaceTapped(Object? id) {
    final place = _placesLayer.placeFor(id);
    if (place == null) return;
    unawaited(RealMapPlaceSheet.show(context, place));
  }

  Future<void> _applyHighlight() async {
    final map = _map;
    if (map == null) return;
    await map.style.setStyleLayerProperty(
      RealMapLayers.highlightLayerId,
      'filter',
      RealMapLayers.highlightFilter(_selected?.county.code),
    );
  }

  void _onCountyTapped(Object? code) {
    MapHomeCountyBadge? badge;
    for (final candidate in widget.badges) {
      if (candidate.county.code == code) badge = candidate;
    }
    if (badge == null) return;
    unawaited(_openPeek(badge));
  }

  Future<void> _openPeek(MapHomeCountyBadge badge) async {
    setState(() => _selected = badge);
    unawaited(_applyHighlight());
    await _flyTo(badge);
    if (!mounted) return;
    await CountyPeekSheet.show(
      context,
      badge,
      isHome: badge.county.slug == widget.homeCountySlug,
    );
    if (!mounted) return;
    setState(() => _selected = null);
    unawaited(_applyHighlight());
    final map = _map;
    if (map != null) RealMapCamera.releaseSheetPadding(map);
  }

  /// Flies into the county, then gives the flight most of its run before
  /// the sheet slides up, so the two motions overlap rather than queue.
  Future<void> _flyTo(MapHomeCountyBadge badge) async {
    final map = _map;
    final bounds = _counties.boundsFor(badge.county.code);
    if (map == null || bounds == null) return;
    // Stop following the user's dot so it doesn't pull the camera back.
    setState(() => _viewport = const IdleViewportState());
    unawaited(
      RealMapCamera.flyToCounty(
        map,
        bounds,
        screen: _mapSize,
        sheetShare: 0.45,
        topPadding: widget.topInset,
        pitch: _pitch,
      ),
    );
    await Future<void>.delayed(RealMapCamera.flightDuration * 0.6);
  }

  void _setTerrainEnabled(bool enabled) {
    if (enabled == _terrainEnabled) return;
    setState(() => _terrainEnabled = enabled);
    final map = _map;
    if (map == null) return;
    unawaited(RealMapLayers.setTerrainEnabled(map.style, enabled));
    RealMapCamera.tiltTo(map, _pitch);
  }

  void _setBaseStyle(RealMapBaseStyle style) {
    if (style == _baseStyle) return;
    setState(() => _baseStyle = style);
    // Layers are re-added by the style-loaded listener.
    unawaited(_map?.style.setStyleURI(style.uri));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _mapSize = constraints.biggest;
        final selected = _selected;
        return Stack(
          children: [
            MapWidget(
              key: const ValueKey('kaunti47-pro-map'),
              styleUri: _baseStyle.uri,
              viewport: _viewport,
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: (_) => unawaited(_onStyleLoaded()),
            // Only a style failure is fatal; a missing tile or sprite isn't.
            onMapLoadErrorListener: (event) {
              if (event.type == MapLoadErrorType.STYLE) _fail();
            },
            ),
            Positioned(
              top: widget.topInset + 8,
              right: 16,
              child: RealMapSideControls(
                baseStyle: _baseStyle,
                onBaseStyleChanged: _setBaseStyle,
                terrainEnabled: _terrainEnabled,
                onTerrainChanged: _setTerrainEnabled,
                onLocate: _focusOnUser,
              ),
            ),
            if (selected != null)
              Positioned(
                top: widget.topInset + 52,
                left: 24,
                child: IgnorePointer(child: MapHomeCountyLabel(badge: selected)),
              ),
          ],
        );
      },
    );
  }
}
