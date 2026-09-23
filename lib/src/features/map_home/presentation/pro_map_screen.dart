import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../design/app_colors.dart';
import '../application/county_geojson_builder.dart';
import '../application/place_geojson_builder.dart';
import '../domain/map_home_models.dart';
import '../domain/map_place.dart';
import 'county_peek_sheet.dart';
import 'map_home_map_overlays.dart';
import 'pro_map_layers.dart';
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

  final _initialViewport = CameraViewportState(
    center: Point(coordinates: Position(37.9, 0.3)),
    zoom: 5.1,
  );

  MapboxMap? _map;
  String? _countyGeoJson;
  ProMapBaseStyle _baseStyle = ProMapBaseStyle.outdoors;
  MapHomeCountyBadge? _selected;
  Future<List<MapPlace>>? _places;
  Map<String, MapPlace> _placesById = const {};

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(widget.accessToken);
    _places = widget.loadPlaces?.call();
  }

  Future<String> _geoJson() async {
    final cached = _countyGeoJson;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_geoJsonAsset);
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
    map.addInteraction(
      TapInteraction(
        FeaturesetDescriptor(layerId: ProMapLayers.placeDotLayerId),
        (feature, _) => _onPlaceTapped(feature.properties['id']),
      ),
      interactionID: 'kaunti47-place-tap',
    );
  }

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null) return;
    final geoJson = await _geoJson();
    await ProMapLayers.addTo(map.style, geoJson);
    await _applyHighlight();
    await _addPlaces(map);
  }

  Future<void> _addPlaces(MapboxMap map) async {
    final pending = _places;
    if (pending == null) return;
    final List<MapPlace> places;
    try {
      places = await pending;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't load places.")));
      return;
    }
    if (!mounted) return;
    _placesById = {for (final place in places) place.id: place};
    await ProMapLayers.addPlacesTo(
      map.style,
      PlaceGeoJsonBuilder.build(places),
    );
  }

  void _onPlaceTapped(Object? id) {
    final place = _placesById[id];
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
              child: SegmentedButton<ProMapBaseStyle>(
                segments: [
                  for (final style in ProMapBaseStyle.values)
                    ButtonSegment(value: style, label: Text(style.label)),
                ],
                selected: {_baseStyle},
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.white,
                  selectedBackgroundColor: AppColors.accent,
                  selectedForegroundColor: Colors.white,
                ),
                onSelectionChanged: (value) => _setBaseStyle(value.first),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
