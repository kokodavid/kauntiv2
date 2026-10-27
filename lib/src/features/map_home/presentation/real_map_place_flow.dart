import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar;
import 'package:flutter/widgets.dart';
// Mapbox exports its own `Size`; this file means Flutter's.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../core/domain/map_place.dart';
import '../../../core/map/map_place_layers.dart';
import '../../../core/map/map_places_layer.dart';
import '../../../core/widgets/app_photo_parts.dart'
    show AppOpenDirections, openRoute;
import '../../../core/widgets/app_place_sheet.dart';
import 'map_popup_faces.dart';
import 'map_popup_layout.dart';
import 'real_map_camera.dart';
import 'real_map_place_popup.dart';

/// What happens when a pin is tapped on Home's map: the pin hides, a popup
/// grows out of it, and the camera zooms in and moves to put the pin where
/// the popup's tail points. Closing reverses it.
class RealMapPlaceFlow {
  RealMapPlaceFlow({
    required this.mapOf,
    required this.contextOf,
    required this.screenOf,
    required this.topInsetOf,
    required this.onWillOpen,
    required this.onOpenPlace,
    required this.onRoute,
    required this.onPlaceRoute,
  }) {
    _popup.onGone = _finish;
  }

  final MapboxMap? Function() mapOf;
  final BuildContext Function() contextOf;
  final Size Function() screenOf;
  final double Function() topInsetOf;

  /// Runs before a popup opens (Home closes a county peek).
  final VoidCallback onWillOpen;
  final AppOpenPlace? Function() onOpenPlace;
  final AppOpenDirections? Function() onRoute;
  final AppOpenPlaceRoute? Function() onPlaceRoute;

  final _popup = RealMapPlacePopup();
  MapPlace? _place;
  int _token = 0;

  /// Room kept under the card for Home's nav bar.
  static const _bottomReserve = 120.0;
  static const _minZoom = 9.5;

  bool get isOpen => _popup.isOpen;

  /// Adds the place pins to [map]'s style, with a note when they can't load.
  static Future<void> addPins(
    BuildContext context,
    MapPlacesLayer layer,
    MapboxMap map,
  ) async {
    final loaded = await layer.addTo(map.style);
    if (loaded || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Couldn't load places.")));
  }

  Future<void> open(MapPlace place) async {
    final map = mapOf();
    if (map == null) return;
    final token = ++_token;
    onWillOpen();
    await _restorePin(map);
    final screen = screenOf();
    final layout = MapPopupLayout(
      screen: screen,
      topInset: topInsetOf(),
      bottomReserve: _bottomReserve,
    );
    final spot = Point(coordinates: Position(place.lng, place.lat));
    final from = await map.pixelForCoordinate(spot);
    if (token != _token) return;
    _place = place;
    await MapPlaceLayers.hidePlace(map, place.id);
    if (token != _token) return;
    final context = contextOf();
    final route = onRoute();
    final placeRoute = onPlaceRoute();
    final openPlace = onOpenPlace();
    _popup.show(
      context,
      layout: layout,
      from: Offset(from.x, from.y),
      to: Offset(screen.width / 2, layout.anchorY),
      onClose: close,
      front: (flip, close) =>
          MapPopupFront(place: place, onDetails: flip, onClose: close),
      back: (flip, close) => MapPopupBack(
        place: place,
        onClose: close,
        onOpen: openPlace == null
            ? null
            : () {
                close();
                openPlace(context, place.id);
              },
        onRoute: route == null && placeRoute == null
            ? null
            : () {
                close();
                if (placeRoute != null) {
                  unawaited(placeRoute(context, place));
                } else {
                  unawaited(
                    openRoute(context, '${place.lat},${place.lng}', route!),
                  );
                }
              },
      ),
    );
    final camera = await map.getCameraState();
    await RealMapCamera.easeToPlace(
      map,
      lat: place.lat,
      lng: place.lng,
      zoom: math.max(camera.zoom, _minZoom),
      padding: layout.cameraPadding,
    );
    // The ease can report done as it starts; give it time to land before
    // reading where the pin ended up.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (token != _token || !_popup.isOpen) return;
    final landed = await map.pixelForCoordinate(spot);
    if (token == _token) _popup.reanchor(Offset(landed.x, landed.y));
  }

  /// Shrinks the popup back into its pin.
  void close() {
    _token++;
    final map = mapOf();
    if (map != null) {
      unawaited(RealMapCamera.dropPaddingInPlace(map, screenOf()));
    }
    _popup.close();
  }

  void _finish() {
    final map = mapOf();
    if (map != null) unawaited(_restorePin(map));
  }

  Future<void> _restorePin(MapboxMap map) async {
    if (_place == null) return;
    _place = null;
    await MapPlaceLayers.hidePlace(map, null);
  }

  /// Takes everything away at once (the map is leaving the screen).
  void dispose() {
    _token++;
    _popup.dispose();
    final map = mapOf();
    if (map != null) unawaited(_restorePin(map));
  }
}
