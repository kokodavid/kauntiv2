part of 'replay_route_map.dart';

extension _ReplayRouteMapHelpers on _ReplayRouteMapState {
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
        ? ReplayMapLayers.emptyJson
        : jsonEncode(played.toGeoJson());
  }

  String _markerJson() {
    return ReplayMapLayers.markerJson(
      widget.marker,
      tipFrom: widget.played?.lastPoint,
    );
  }

  String _endpointJson() => ReplayMapLayers.endpointsJson(
    start: widget.start,
    end: widget.end,
    moments: widget.moments,
    currentIndex: widget.currentIndex,
  );

  /// Keeps the marker's pulse in sync with the current replay state.
  void _syncPulse() {
    if (!_styleReady) return;
    if (widget.pulsing) {
      _pulseTimer ??= Timer.periodic(
        const Duration(milliseconds: _ReplayRouteMapState._pulseStepMs),
        (_) {
          _pulseElapsedMs =
              (_pulseElapsedMs + _ReplayRouteMapState._pulseStepMs) %
              _ReplayRouteMapState._pulsePeriodMs;
          final phase = _pulseElapsedMs / _ReplayRouteMapState._pulsePeriodMs;
          final radius =
              _ReplayRouteMapState._markerBaseRadius +
              _ReplayRouteMapState._markerPulseAmplitude *
                  (0.5 - 0.5 * math.cos(2 * math.pi * phase));
          unawaited(
            _map?.style.setStyleLayerProperty(
              'replay-marker',
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
          'replay-marker',
          'circle-radius',
          _ReplayRouteMapState._markerBaseRadius,
        ),
      );
    }
  }
}
