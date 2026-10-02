part of 'journey_route_map.dart';

extension _JourneyRouteMapHelpers on _JourneyRouteMapState {
  EdgeInsets? _viewportPadding(MbxEdgeInsets? padding) => padding == null
      ? null
      : EdgeInsets.fromLTRB(
          padding.left,
          padding.top,
          padding.right,
          padding.bottom,
        );

  String _routeJson() => jsonEncode(widget.route.toGeoJson());

  String _playedJson() {
    final played = widget.played;
    return played == null
        ? JourneyMapLayers.emptyJson
        : jsonEncode(played.toGeoJson());
  }

  String _markerJson() {
    final tip = widget.played?.segments.lastOrNull?.lastOrNull;
    return JourneyMapLayers.markerJson(
      widget.marker,
      tipFrom: tip == null
          ? null
          : (latitude: tip.latitude, longitude: tip.longitude),
    );
  }

  String _endpointJson() => JourneyMapLayers.pinsJson([
    for (final at in widget.pins) (kind: 'moment', at: at),
    if (widget.start case final at?) (kind: 'start', at: at),
    if (widget.end case final at?) (kind: 'end', at: at),
  ]);

  /// Keeps the marker's pulse in sync with the current replay state.
  void _syncPulse() {
    if (!_styleReady) return;
    if (widget.pulsing) {
      _pulseTimer ??= Timer.periodic(
        const Duration(milliseconds: _JourneyRouteMapState._pulseStepMs),
        (_) {
          _pulseElapsedMs =
              (_pulseElapsedMs + _JourneyRouteMapState._pulseStepMs) %
              _JourneyRouteMapState._pulsePeriodMs;
          final phase = _pulseElapsedMs / _JourneyRouteMapState._pulsePeriodMs;
          final radius =
              _JourneyRouteMapState._markerBaseRadius +
              _JourneyRouteMapState._markerPulseAmplitude *
                  (0.5 - 0.5 * math.cos(2 * math.pi * phase));
          unawaited(
            _map?.style.setStyleLayerProperty(
              'journey-marker',
              'circle-radius',
              radius,
            ),
          );
        },
      );
    } else if (_pulseTimer != null) {
      _pulseTimer?.cancel();
      _pulseTimer = null;
      _pulseElapsedMs = 0;
      unawaited(
        _map?.style.setStyleLayerProperty(
          'journey-marker',
          'circle-radius',
          _JourneyRouteMapState._markerBaseRadius,
        ),
      );
    }
  }
}
