import 'dart:async';

import 'package:flutter/material.dart';
// Mapbox exports its own `Size`; this file means Flutter's.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../core/services/app_current_location.dart';
import '../../../core/services/app_mapbox_telemetry.dart';
import '../../../services/app_location_permission_service.dart';
import '../application/real_map_start_focus.dart';
import '../domain/map_home_models.dart';
import '../domain/map_place.dart';
import 'county_peek_sheet.dart';
import 'map_home_links.dart';
import 'map_home_map_overlays.dart';
import 'real_map_camera.dart';
import 'real_map_controls.dart';
import 'real_map_county_source.dart';
import 'real_map_focus.dart';
import 'real_map_layers.dart';
import 'real_map_load_watch.dart';
import 'real_map_place_sheet.dart';
import 'real_map_places_layer.dart';

/// Home's default map: the county map on a real Mapbox base map, edge to
/// edge behind Home's header, sheet and nav. Same badges and colours as the
/// drawn map; tapping a county flies to it and opens the peek. Reports
/// [onReady] once the style and county layers are up, or [onFailed] if they
/// can't load (no signal, bad token, timeout), so Home falls back.
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
    this.onOpenCounty,
    this.onOpenPlace,
    this.onRoute,
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
  final OpenCountyDetail? onOpenCounty;
  final OpenPlaceDetail? onOpenPlace;
  final OpenDirections? onRoute;

  @override
  State<RealMapView> createState() => _RealMapViewState();
}

class _RealMapViewState extends State<RealMapView> {
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
  late final RealMapLoadWatch _load;
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
    _load = RealMapLoadWatch(
      onReady: () => widget.onReady?.call(),
      onFailed: () => widget.onFailed?.call(),
    );
  }

  @override
  void dispose() {
    _load.dispose();
    super.dispose();
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

  /// Opening camera and "locate me": one position read, one flight, no
  /// following afterwards. Outside Kenya or without a fix, the home county.
  Future<void> _focusOnUser() async {
    final location = _hasLocation ? await AppCurrentLocation.read() : null;
    await _counties.geoJson();
    if (!mounted) return;
    final home = widget.badges
        .where((badge) => badge.county.slug == widget.homeCountySlug)
        .firstOrNull;
    final focus = RealMapStartFocus.decide(
      location: location,
      homeCounty: _counties.boundsFor(home?.county.code),
    );
    setState(() => _viewport = RealMapFocus.viewportFor(focus, _pitch));
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
    _load.ready();
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
    unawaited(
      RealMapPlaceSheet.show(
        context,
        place,
        onOpenPlace: widget.onOpenPlace,
        onRoute: widget.onRoute,
      ),
    );
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
    final badge = widget.badges
        .where((candidate) => candidate.county.code == code)
        .firstOrNull;
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
      onOpen: widget.onOpenCounty == null
          ? null
          : () => widget.onOpenCounty!(context, badge.county.code),
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
                if (event.type == MapLoadErrorType.STYLE) _load.fail();
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
                child: IgnorePointer(
                  child: MapHomeCountyLabel(badge: selected),
                ),
              ),
          ],
        );
      },
    );
  }
}
