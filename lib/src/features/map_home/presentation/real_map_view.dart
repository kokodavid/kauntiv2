import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../core/domain/map_place.dart';
import '../../../core/map/map_places_layer.dart';
import '../../../core/services/app_current_location.dart';
import '../../../core/services/app_mapbox_telemetry.dart';
import '../../../services/app_location_permission_service.dart';
import '../application/real_map_start_focus.dart';
import '../domain/map_home_models.dart';
import 'map_home_links.dart';
import 'map_home_map_overlays.dart';
import 'real_map_camera.dart';
import 'real_map_controls.dart';
import 'real_map_county_source.dart';
import 'real_map_focus.dart';
import 'real_map_layers.dart';
import 'real_map_load_watch.dart';
import 'real_map_place_flow.dart';
import 'real_map_sheets.dart';

/// Home's default map: the county map on a real Mapbox base map, behind
/// Home's header, sheet and nav. A county tap flies to it and opens the
/// peek; a pin tap opens a popup. [onReady] / [onFailed] tell Home whether
/// the style and layers loaded, so it can fall back.
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
    this.onPlaceRoute,
  });

  final String accessToken;
  final List<MapHomeCountyBadge> badges;
  final String? homeCountySlug;

  /// Loads the pins for `places`; null shows counties only.
  final Future<List<MapPlace>> Function()? loadPlaces;

  /// Header inset for controls and county camera framing.
  final double topInset;

  final VoidCallback? onReady;
  final VoidCallback? onFailed;
  final OpenCountyDetail? onOpenCounty;
  final OpenPlaceDetail? onOpenPlace;
  final OpenDirections? onRoute;
  final OpenPlaceDirections? onPlaceRoute;

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
  late final MapPlacesLayer _placesLayer;
  late final _sheets = RealMapSheets(onPeekClosed: _onPeekClosed);
  int _peekTap = 0;
  late final _placeFlow = RealMapPlaceFlow(
    mapOf: () => _map,
    contextOf: () => context,
    screenOf: () => _mapSize,
    topInsetOf: () => widget.topInset,
    onWillOpen: _sheets.closePeek,
    onOpenPlace: () => widget.onOpenPlace,
    onRoute: () => widget.onRoute,
    onPlaceRoute: () => widget.onPlaceRoute,
  );

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(widget.accessToken);
    _placesLayer = MapPlacesLayer(widget.loadPlaces?.call());
    unawaited(_focusOnStart());
    _load = RealMapLoadWatch(
      onReady: () => widget.onReady?.call(),
      onFailed: () => widget.onFailed?.call(),
    );
  }

  @override
  void dispose() {
    _sheets.dispose();
    _placeFlow.dispose();
    _load.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.valuesOf(context).enabled) {
      _sheets.closePeek();
      _placeFlow.dispose();
    }
  }

  /// Satellite stays flat: a tilted view shows far more of the map to the
  /// horizon, and satellite's heavy tiles then trip Mapbox's rate limit.
  double get _pitch =>
      _terrainEnabled && _baseStyle != RealMapBaseStyle.satellite
      ? _tiltedPitch
      : 0;

  Future<void> _focusOnStart() async {
    _hasLocation = await const AppLocationPermissionService()
        .hasForegroundLocation();
    if (!mounted) return;
    final map = _map;
    if (_hasLocation && map != null) unawaited(RealMapFocus.showUserDot(map));
    await _focusOnUser();
  }

  /// Opening camera and "locate me": one position read, one flight. Outside
  /// Kenya or without a fix, the home county.
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
    RealMapFocus.prepare(
      map,
      hasLocation: _hasLocation,
      bottomInset: MediaQuery.sizeOf(context).height * 0.16,
    );
    RealMapLayers.addTapHandlers(
      map,
      onCounty: _onCountyTapped,
      onPlace: (id) {
        final place = _placesLayer.placeFor(id);
        if (place != null) unawaited(_placeFlow.open(place));
      },
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
    if (mounted) await RealMapPlaceFlow.addPins(context, _placesLayer, map);
  }

  Future<void> _applyHighlight() async {
    final map = _map;
    if (map != null) await RealMapLayers.setHighlight(map, _selected);
  }

  void _onCountyTapped(Object? code) {
    final badge = widget.badges
        .where((candidate) => candidate.county.code == code)
        .firstOrNull;
    if (badge == null) return;
    unawaited(_openPeek(badge));
  }

  /// The latest tap wins: it replaces a peek that is flying in or showing.
  Future<void> _openPeek(MapHomeCountyBadge badge) async {
    final tap = ++_peekTap;
    setState(() => _selected = badge);
    unawaited(_applyHighlight());
    final map = _map;
    final bounds = _counties.boundsFor(badge.county.code);
    if (map == null || bounds == null) return;
    setState(() => _viewport = const IdleViewportState());
    // Returns once most of the flight has run.
    await RealMapCamera.flyToCountyThenSettle(
      map,
      bounds,
      screen: _mapSize,
      topPadding: widget.topInset,
      pitch: _pitch,
    );
    if (!mounted || tap != _peekTap) return;
    _sheets.showCounty(
      context,
      badge,
      isHome: badge.county.slug == widget.homeCountySlug,
      onOpen: widget.onOpenCounty == null
          ? null
          : () => widget.onOpenCounty!(context, badge.county.code),
    );
  }

  void _onPeekClosed() {
    _peekTap++;
    if (!mounted) return;
    setState(() => _selected = null);
    unawaited(_applyHighlight());
    final map = _map;
    if (map != null) RealMapCamera.releaseSheetPadding(map);
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
    final map = _map;
    if (map == null) return;
    // Flatten (or re-tilt) first so the new style loads fewer tiles.
    RealMapCamera.tiltTo(map, _pitch);
    unawaited(map.style.setStyleURI(style.uri));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (!size.width.isFinite ||
            !size.height.isFinite ||
            size.width <= 0 ||
            size.height <= 0) {
          return const SizedBox.shrink();
        }
        _mapSize = size;
        final selected = _selected;
        return Stack(
          children: [
            Positioned.fill(
              child: MapWidget(
                key: const ValueKey('kaunti47-pro-map'),
                styleUri: _baseStyle.uri,
                viewport: _viewport,
                onMapCreated: _onMapCreated,
                onStyleLoadedListener: (_) => unawaited(_onStyleLoaded()),
                onMapLoadErrorListener: (event) {
                  if (event.type == MapLoadErrorType.STYLE) _load.fail();
                },
              ),
            ),
            RealMapSideControls(
              top: widget.topInset + 8,
              baseStyle: _baseStyle,
              onBaseStyleChanged: _setBaseStyle,
              terrainEnabled: _terrainEnabled,
              onTerrainChanged: _setTerrainEnabled,
              onLocate: _focusOnUser,
            ),
            if (selected != null)
              MapHomeCountyLabelSlot(
                top: widget.topInset + 52,
                badge: selected,
              ),
          ],
        );
      },
    );
  }
}
