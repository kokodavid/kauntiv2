import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../design/app_colors.dart';
import '../application/county_camera_fit.dart';
import '../application/county_geojson_builder.dart';
import '../domain/map_home_models.dart';
import '../domain/map_place.dart';
import 'county_peek_sheet.dart';
import 'map_home_map_overlays.dart';
import 'pro_map_camera.dart';
import 'pro_map_controls.dart';
import 'pro_map_layers.dart';
import 'pro_map_places_layer.dart';
import 'pro_map_place_widgets.dart';

/// SPIKE (codex/mapbox-spike): the county map on a real Mapbox base map,
/// evaluated as a possible Pro feature. Same badge data and colours as the
/// drawn map; tapping a county outlines it and opens the peek sheet.
class ProMapScreen extends StatefulWidget {
  const ProMapScreen({
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

  /// Dev toggle for the spike: the entry point only shows with a token.
  static bool get isAvailable => configuredAccessToken.isNotEmpty;

  final String accessToken;
  final List<MapHomeCountyBadge> badges;
  final String? homeCountySlug;

  /// Loads the pins for `places`; null shows counties only.
  final Future<List<MapPlace>> Function()? loadPlaces;

  @override
  State<ProMapScreen> createState() => _ProMapScreenState();
}

class _ProMapScreenState extends State<ProMapScreen> {
  static const _geoJsonAsset = 'assets/geo/kenya_counties.geojson';

  static const _tiltedPitch = 50.0;

  final _initialViewport = CameraViewportState(
    center: Point(coordinates: Position(37.9, 0.3)),
    zoom: 5.1,
    pitch: _tiltedPitch,
  );

  bool _terrainEnabled = true;

  MapboxMap? _map;
  String? _countyGeoJson;
  Map<int, CountyBounds> _countyBounds = const {};
  ProMapBaseStyle _baseStyle = ProMapBaseStyle.outdoors;
  MapHomeCountyBadge? _selected;
  late final ProMapPlacesLayer _placesLayer;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(widget.accessToken);
    _placesLayer = ProMapPlacesLayer(widget.loadPlaces?.call());
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
    map.addInteraction(
      TapInteraction(
        FeaturesetDescriptor(layerId: ProMapLayers.fillLayerId),
        (feature, _) => _onCountyTapped(feature.properties['code']),
      ),
      interactionID: 'kaunti47-county-tap',
    );
    // Added after the county tap so a pin wins over the county under it.
    for (final layerId in [
      ProMapLayers.placeDotLayerId,
      ProMapLayers.placeMarkerLayerId,
    ]) {
      map.addInteraction(
        TapInteraction(
          FeaturesetDescriptor(layerId: layerId),
          (feature, _) => _onPlaceTapped(feature.properties['id']),
        ),
        interactionID: 'kaunti47-place-tap-$layerId',
      );
    }
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
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: AppColors.foreground.withValues(alpha: 0.28),
        builder: (context) => ProMapPlaceSheet(place: place),
      ),
    );
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
    unawaited(
      ProMapCamera.flyToCounty(
        map,
        bounds,
        screen: MediaQuery.sizeOf(context),
        pitch: _terrainEnabled ? _tiltedPitch : 0,
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
    unawaited(
      map.easeTo(
        CameraOptions(pitch: enabled ? _tiltedPitch : 0),
        MapAnimationOptions(duration: 800),
      ),
    );
  }

  void _setBaseStyle(ProMapBaseStyle style) {
    if (style == _baseStyle) return;
    setState(() => _baseStyle = style);
    // Layers are re-added by the style-loaded listener.
    unawaited(_map?.style.setStyleURI(style.uri));
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('kaunti47-pro-map'),
            styleUri: _baseStyle.uri,
            viewport: _initialViewport,
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: (_) => unawaited(_onStyleLoaded()),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton.filled(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.mapOverlayBackground,
                        ),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.mapOverlayForeground,
                        ),
                      ),
                      if (widget.loadPlaces != null) ...[
                        const SizedBox(height: 8),
                        const ProMapPlaceLegend(),
                      ],
                    ],
                  ),
                  const Spacer(),
                  if (selected != null) MapHomeCountyLabel(badge: selected),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: ProMapControls(
                baseStyle: _baseStyle,
                onBaseStyleChanged: _setBaseStyle,
                terrainEnabled: _terrainEnabled,
                onTerrainChanged: _setTerrainEnabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
