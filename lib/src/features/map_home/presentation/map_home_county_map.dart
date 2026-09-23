import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../counties/county_paths.dart';
import '../domain/map_home_models.dart';
import 'county_peek_sheet.dart';
import 'map_home_county_map_painter.dart';
import 'map_home_map_overlays.dart';

/// Map Home's full-bleed county map, ported from v1's
/// `MapHomeCountyMapCard`: press highlights a county and shows its label,
/// pinch-zoom (1x-4x) with an animated reset, and a touch halo for tiny
/// counties.
///
/// Until County Detail is ported, both tap and long-press open the peek
/// sheet (v1: tap opens County Detail, long-press opens the peek).
class MapHomeCountyMap extends StatefulWidget {
  const MapHomeCountyMap({
    super.key,
    required this.badges,
    required this.homeCountySlug,
    this.onInteractingChanged,
  });

  final List<MapHomeCountyBadge> badges;
  final String? homeCountySlug;

  /// Fires when the map flips between idle and being browsed (a gesture in
  /// progress, zoomed in, or a county held). Drives the compact stat card.
  final ValueChanged<bool>? onInteractingChanged;

  @override
  State<MapHomeCountyMap> createState() => _MapHomeCountyMapState();
}

class _MapHomeCountyMapState extends State<MapHomeCountyMap>
    with SingleTickerProviderStateMixin {
  static const _minZoom = 1.0;
  static const _maxZoom = 4.0;

  final _transformationController = TransformationController();
  late final AnimationController _resetController;
  Animation<Matrix4>? _resetAnimation;

  String? _hoveredCountySlug;
  String? _pressedCountySlug;
  double _zoom = _minZoom;
  bool _gestureActive = false;
  bool _lastReportedInteracting = false;

  String? get _highlightedCountySlug =>
      _pressedCountySlug ?? _hoveredCountySlug;

  MapHomeCountyBadge? get _highlightedBadge {
    final slug = _highlightedCountySlug;
    if (slug == null) return null;
    for (final badge in widget.badges) {
      if (badge.county.slug == slug) return badge;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(_applyResetFrame);
    _transformationController.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransformChanged);
    _transformationController.dispose();
    _resetController.dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    final zoom = _transformationController.value.getMaxScaleOnAxis();
    if ((zoom - _zoom).abs() < 0.001) return;
    setState(() => _zoom = zoom);
    _reportInteractingIfChanged();
  }

  void _reportInteractingIfChanged() {
    final callback = widget.onInteractingChanged;
    if (callback == null) return;
    final interacting =
        _gestureActive || _zoom > _minZoom + 0.01 || _pressedCountySlug != null;
    if (interacting == _lastReportedInteracting) return;
    _lastReportedInteracting = interacting;
    callback(interacting);
  }

  void _setGestureActive(bool active) {
    _gestureActive = active;
    _reportInteractingIfChanged();
  }

  void _applyResetFrame() {
    final animation = _resetAnimation;
    if (animation != null) _transformationController.value = animation.value;
  }

  void _resetZoom() {
    _resetAnimation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: Matrix4.identity(),
        ).animate(
          CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
        );
    unawaited(_resetController.forward(from: 0));
  }

  MapHomeCountyBadge? _badgeAt(Offset position, Size size) {
    return MapHomeCountiesPainter.badgeAt(
      widget.badges,
      position,
      size,
      zoom: _zoom,
    );
  }

  void _setPressedCounty(String? slug) {
    if (slug == _pressedCountySlug) return;
    setState(() => _pressedCountySlug = slug);
    _reportInteractingIfChanged();
  }

  void _setHoveredCounty(String? slug) {
    if (slug == _hoveredCountySlug) return;
    setState(() => _hoveredCountySlug = slug);
  }

  /// Keeps the county highlighted under the sheet; clears it on close.
  Future<void> _openPeek(MapHomeCountyBadge badge) async {
    _setPressedCounty(badge.county.slug);
    await CountyPeekSheet.show(
      context,
      badge,
      isHome: badge.county.slug == widget.homeCountySlug,
    );
    if (!mounted) return;
    _setPressedCounty(null);
  }

  @override
  Widget build(BuildContext context) {
    final map = Semantics(
      label:
          "Interactive map of Kenya's 47 counties, shaded by badge status. "
          'Tap or press and hold a county to preview it.',
      button: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            onHover: (event) => _setHoveredCounty(
              _badgeAt(event.localPosition, size)?.county.slug,
            ),
            onExit: (_) => _setHoveredCounty(null),
            child: GestureDetector(
              key: const ValueKey('map-home-interactive-map'),
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _setPressedCounty(
                _badgeAt(details.localPosition, size)?.county.slug,
              ),
              onTapCancel: () => _setPressedCounty(null),
              onTapUp: (details) {
                final badge = _badgeAt(details.localPosition, size);
                if (badge == null) {
                  _setPressedCounty(null);
                  return;
                }
                unawaited(_openPeek(badge));
              },
              onLongPressStart: (details) {
                final badge = _badgeAt(details.localPosition, size);
                if (badge == null) return;
                unawaited(HapticFeedback.selectionClick());
                unawaited(_openPeek(badge));
              },
              child: CustomPaint(
                painter: MapHomeCountiesPainter(
                  badges: widget.badges,
                  highlightedCountySlug: _highlightedCountySlug,
                  homeCountySlug: widget.homeCountySlug,
                ),
              ),
            ),
          );
        },
      ),
    );

    // The gesture detector sits inside the InteractiveViewer's child, so
    // pointer positions arrive in unzoomed coordinates; only the halo in
    // badgeAt needs the live zoom.
    final highlighted = _highlightedBadge;
    return Align(
      alignment: Alignment.topCenter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: CountyPaths.viewBoxWidth / CountyPaths.viewBoxHeight,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: _minZoom,
              maxScale: _maxZoom,
              onInteractionStart: (_) => _setGestureActive(true),
              onInteractionEnd: (_) => _setGestureActive(false),
              child: map,
            ),
          ),
          if (highlighted != null)
            Positioned(
              top: 8,
              right: 8,
              child: IgnorePointer(
                child: MapHomeCountyLabel(badge: highlighted),
              ),
            ),
          if (_zoom > _minZoom + 0.01)
            Positioned(
              bottom: 8,
              right: 8,
              child: MapHomeMapResetChip(onTap: _resetZoom),
            ),
        ],
      ),
    );
  }
}
