import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Mapbox exports its own `Size`; this file means Flutter's.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../design/app_colors.dart';
import '../../../services/app_location_permission_service.dart';
import '../application/county_camera_fit.dart';
import '../application/county_geojson_builder.dart';
import '../domain/map_home_models.dart';
import '../domain/map_place.dart';
import 'county_peek_sheet.dart';
import 'map_home_map_overlays.dart';
import 'pro_map_camera.dart';
import 'pro_map_controls.dart';
import 'pro_map_focus.dart';
import 'pro_map_layers.dart';
import 'pro_map_place_widgets.dart';
import 'pro_map_places_layer.dart';

/// SPIKE (codex/mapbox-spike): the county map on a real Mapbox base map,
/// evaluated as a possible Pro feature. Swapped in for the drawn map inside
/// Map Home's map slot (the rest of Home stays put). Same badge data and
/// colours as the drawn map; tapping a county flies to it and opens the peek.
class ProMapView extends StatefulWidget {
  const ProMapView({
    super.key,
    required this.accessToken,
    required this.badges,
    required this.homeCountySlug,
    this.loadPlaces,
  });

  /// Public Mapbox token (`MAPBOX_ACCESS_TOKEN` dart-define).
  static const configuredAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
  );

  /// Dev toggle for the spike: the Map / Real switch only shows with a token.
  static bool get isAvailable => configuredAccessToken.isNotEmpty;

  final String accessToken;
  final List<MapHomeCountyBadge> badges;
  final String? homeCountySlug;

  /// Loads the pins for `places`; null shows counties only.
  final Future<List<MapPlace>> Function()? loadPlaces;

  @override
  State<ProMapView> createState() => _ProMapViewState();
}

class _ProMapViewState extends State<ProMapView> {
  static const _geoJsonAsset = 'assets/geo/kenya_counties.geojson';

  static const _tiltedPitch = 50.0;

  // Starts on all of Kenya, then flies in to the user (or home county).
  ViewportState _viewport = ProMapFocus.kenya(_tiltedPitch);
  bool _hasLocation = false;

  bool _terrainEnabled = true;

  MapboxMap? _map;
  String? _countyGeoJson;
  Map<int, CountyBounds> _countyBounds = const {};
  ProMapBaseStyle _baseStyle = ProMapBaseStyle.outdoors;
  MapHomeCountyBadge? _selected;
  Size _mapSize = Size.zero;
  late final ProMapPlacesLayer _placesLayer;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(widget.accessToken);
    _placesLayer = ProMapPlacesLayer(widget.loadPlaces?.call());
    unawaited(_focusOnStart());
  }

  double get _pitch => _terrainEnabled ? _tiltedPitch : 0;

  Future<void> _focusOnStart() async {
    _hasLocation = await const AppLocationPermissionService()
        .hasForegroundLocation();
    if (!mounted) return;
    final map = _map;
    if (_hasLocation && map != null) unawaited(ProMapFocus.showUserDot(map));
    await _focusOnUser();
  }

  /// "Locate me": follow the user's dot, or frame the home county when
  /// there's no permission or no fix arrives (e.g. simulator set to None).
  Future<void> _focusOnUser() async {
    if (_hasLocation) {
      final following = ProMapFocus.aroundUser(_pitch);
      setState(() => _viewport = following);
      final map = _map;
      if (map == null || await ProMapFocus.reachedUser(map)) return;
      if (!mounted || _viewport != following) return;
    }
    await _geoJson();
    final home = widget.badges
        .where((badge) => badge.county.slug == widget.homeCountySlug)
        .firstOrNull;
    final bounds = _countyBounds[home?.county.code];
    if (!mounted || bounds == null) return;
    setState(() => _viewport = ProMapFocus.aroundHomeCounty(bounds, _pitch));
  }

  Future<String> _geoJson() async {
    final cached = _countyGeoJson;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_geoJsonAsset);
    _countyBounds = CountyCameraFit.boundsByCode(raw);
    return _countyGeoJson = CountyGeoJsonBuilder.withBadgeStates(
      boundariesGeoJson: raw,
      badges: widget.badges,
      homeCountySlug: widget.homeCountySlug,
    );
  }

  void _onMapCreated(MapboxMap map) {
    _map = map;
    if (_hasLocation) unawaited(ProMapFocus.showUserDot(map));
    unawaited(
      ProMapFocus.placeOrnaments(
        map,
        bottomInset: MediaQuery.sizeOf(context).height * 0.16,
      ),
    );
    // Keep the camera on Kenya.
    unawaited(
      map.setBounds(
        CameraBoundsOptions(
          bounds: CoordinateBounds(
            southwest: Point(coordinates: Position(33.0, -5.5)),
            northeast: Point(coordinates: Position(42.5, 5.5)),
            infiniteBounds: false,
          ),
          minZoom: 4.3,
        ),
      ),
    );
    ProMapLayers.addTapHandlers(
      map,
      onCounty: _onCountyTapped,
      onPlace: _onPlaceTapped,
    );
  }

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null) return;
    final geoJson = await _geoJson();
    await ProMapLayers.addTerrainTo(map.style, enabled: _terrainEnabled);
    await ProMapLayers.addTo(map.style, geoJson);
    await _applyHighlight();
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
    unawaited(ProMapPlaceSheet.show(context, place));
  }

  Future<void> _applyHighlight() async {
    final map = _map;
    if (map == null) return;
    await map.style.setStyleLayerProperty(
      ProMapLayers.highlightLayerId,
      'filter',
      ProMapLayers.highlightFilter(_selected?.county.code),
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
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.foreground.withValues(alpha: 0.28),
      builder: (context) => CountyPeekSheet(
        badge: badge,
        isHome: badge.county.slug == widget.homeCountySlug,
      ),
    );
    if (!mounted) return;
    setState(() => _selected = null);
    unawaited(_applyHighlight());
    final map = _map;
    if (map != null) ProMapCamera.releaseSheetPadding(map);
  }

  /// Flies into the county, then gives the flight most of its run before
  /// the sheet slides up, so the two motions overlap rather than queue.
  Future<void> _flyTo(MapHomeCountyBadge badge) async {
    final map = _map;
    final bounds = _countyBounds[badge.county.code];
    if (map == null || bounds == null) return;
    // Stop following the user's dot so it doesn't pull the camera back.
    setState(() => _viewport = const IdleViewportState());
    unawaited(
      ProMapCamera.flyToCounty(
        map,
        bounds,
        screen: _mapSize,
        // The peek sheet covers most of Home's map slot.
        sheetShare: 0.6,
        pitch: _pitch,
      ),
    );
    await Future<void>.delayed(ProMapCamera.flightDuration * 0.6);
  }

  void _setTerrainEnabled(bool enabled) {
    if (enabled == _terrainEnabled) return;
    setState(() => _terrainEnabled = enabled);
    final map = _map;
    if (map == null) return;
    unawaited(ProMapLayers.setTerrainEnabled(map.style, enabled));
    ProMapCamera.tiltTo(map, _pitch);
  }

  void _setBaseStyle(ProMapBaseStyle style) {
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
            ),
            Positioned(
              top: 56,
              right: 16,
              child: ProMapSideControls(
                baseStyle: _baseStyle,
                onBaseStyleChanged: _setBaseStyle,
                terrainEnabled: _terrainEnabled,
                onTerrainChanged: _setTerrainEnabled,
                onLocate: _focusOnUser,
              ),
            ),
            if (selected != null)
              Positioned(
                top: 56,
                left: 24,
                child: IgnorePointer(child: MapHomeCountyLabel(badge: selected)),
              ),
          ],
        );
      },
    );
  }
}
