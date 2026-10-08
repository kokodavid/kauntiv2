import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/map_place.dart';
import '../../../design/app_colors.dart';
import '../application/map_home_view_preference_provider.dart';
import '../domain/map_home_layout.dart';
import '../domain/map_home_models.dart';
import 'map_home_board_sheet.dart';
import 'map_home_board_top.dart';
import 'map_home_drawn_map.dart';
import 'map_home_links.dart';
import 'map_home_map_status.dart';
import 'real_map_controls.dart';
import 'real_map_view.dart';

class MapHomeBoard extends ConsumerStatefulWidget {
  const MapHomeBoard({
    super.key,
    required this.data,
    this.loadMapPlaces,
    this.mapboxAccessToken = '',
    this.onOpenCounty,
    this.onOpenPlace,
    this.onRoute,
    this.onPlaceRoute,
    this.onPromotedPlaceRoute,
    this.onSeeAllUnclaimed,
    this.onOpenProfile,
    this.isTripRecording = false,
    this.onStartTrip,
    this.tripsNear,
    this.savedPlans,
    this.recordTripCard,
    this.recordTripCardHeight = defaultRecordTripCardHeight,
  });

  /// A Trip is recording; starting or stopping one re-picks the layout.
  final bool isTripRecording;
  final VoidCallback? onStartTrip;
  final Widget? tripsNear;
  final Widget? savedPlans;
  final Widget? recordTripCard; // while moving or a Trip is in progress
  final double recordTripCardHeight;

  /// Null while the board is loading: every slot shows a same-sized
  /// placeholder, then crossfades to the real content in place.
  final MapHomeBoardData? data;

  final Future<List<MapPlace>> Function()? loadMapPlaces;

  /// Empty (or web, which Mapbox doesn't support): drawn map only.
  final String mapboxAccessToken;

  final OpenCountyDetail? onOpenCounty;
  final OpenPlaceDetail? onOpenPlace;
  final OpenDirections? onRoute;
  final OpenPlaceDirections? onPlaceRoute;
  final OpenPromotedPlaceDirections? onPromotedPlaceRoute;
  final OpenAllUnclaimed? onSeeAllUnclaimed;
  final VoidCallback? onOpenProfile;

  @override
  ConsumerState<MapHomeBoard> createState() => _MapHomeBoardState();
}

class _MapHomeBoardState extends ConsumerState<MapHomeBoard> {
  bool _isMapInteracting = false;

  /// The real (Mapbox) map is Home's default; the drawn map is the
  /// fallback when it can't load. Once failed, Home stays on the drawn map
  /// until the user retries, so a patchy signal never flips maps mid-use.
  _RealMapStatus _realMap = _RealMapStatus.loading;
  int _realMapAttempt = 0;

  /// The user's own choice of map, independent of [_realMap]'s load/fail
  /// state: the real map still loads normally underneath (so switching
  /// back is instant), it's just not the one shown while this is true.
  /// Loaded from storage on first build and persisted on every toggle.
  bool _preferDrawnMap = false;

  bool get _realMapAllowed => !kIsWeb && widget.mapboxAccessToken.isNotEmpty;

  /// The sheet's layout. Picked once the board and the stored preferences
  /// are in, then re-picked only when a Trip starts or stops, so a late
  /// signal never moves content under the user's thumb.
  MapHomeLayout? _layout;
  bool _prefsLoaded = false;
  DateTime? _celebratedClaimAt;

  /// Decided on the first pick: whether the newest claim is celebrated on
  /// this open. Kept for the session so a Trip starting does not drop it.
  bool _claimIsFresh = false;
  bool _firstPickDone = false;

  void _pickLayout() {
    final data = widget.data;
    if (data == null || !_prefsLoaded) return;
    final claim = data.lastClaim;
    if (!_firstPickDone) {
      _firstPickDone = true;
      _claimIsFresh = MapHomeLayoutRules.isFreshClaim(
        claimedAt: claim?.claimedAt,
        now: DateTime.now(),
        celebratedAt: _celebratedClaimAt,
      );
      if (_claimIsFresh && claim != null) {
        // One open only: the next open goes back to the usual order.
        unawaited(
          ref
              .read(mapHomeViewPreferenceProvider)
              .setCelebratedClaimAt(claim.claimedAt),
        );
      }
    }
    final layout = MapHomeLayoutRules.pick(
      claimedCount: data.exploredCount,
      totalCounties: data.totalCounties,
      isTripRecording: widget.isTripRecording,
      hasFreshClaim: _claimIsFresh && claim != null,
    );
    if (layout != _layout) setState(() => _layout = layout);
  }

  @override
  void didUpdateWidget(MapHomeBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final boardArrived = oldWidget.data == null && widget.data != null;
    if (boardArrived || oldWidget.isTripRecording != widget.isTripRecording) {
      _pickLayout();
    }
  }

  static const _fade = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreferences());
  }

  Future<void> _loadPreferences() async {
    final prefs = ref.read(mapHomeViewPreferenceProvider);
    final preferDrawn = await prefs.preferDrawnMap();
    final celebratedAt = await prefs.celebratedClaimAt();
    if (!mounted) return;
    _celebratedClaimAt = celebratedAt;
    _prefsLoaded = true;
    if (preferDrawn) _preferDrawnMap = true;
    _pickLayout();
    if (preferDrawn) setState(() {});
  }

  void _setPreferDrawnMap(bool preferDrawn) {
    setState(() => _preferDrawnMap = preferDrawn);
    unawaited(
      ref.read(mapHomeViewPreferenceProvider).setPreferDrawnMap(preferDrawn),
    );
  }

  /// Where the header (top bar + stat card) ends, in board coordinates;
  /// the real map keeps its controls and camera framing below it.
  final _headerKey = GlobalKey();
  double _headerBottom = 0;

  void _measureHeader() {
    final header = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    final board = context.findRenderObject() as RenderBox?;
    if (header == null || board == null || !header.hasSize) return;
    final bottom = header
        .localToGlobal(Offset(0, header.size.height), ancestor: board)
        .dy;
    if ((bottom - _headerBottom).abs() < 1) return;
    setState(() => _headerBottom = bottom);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final mountReal =
        data != null && _realMapAllowed && _realMap != _RealMapStatus.failed;
    final realReady = mountReal && _realMap == _RealMapStatus.ready;
    // What's actually on screen: the real map once it's ready, unless the
    // user has chosen the drawn map themselves.
    final showRealMap = realReady && !_preferDrawnMap;
    // Only the automatic path should wait on the real map before showing
    // the drawn map's real content (so a fallback never flashes it right
    // before the real map turns out to succeed); a manual pick shouldn't
    // wait on it at all.
    final waitingOnRealMap =
        mountReal && _realMap == _RealMapStatus.loading && !_preferDrawnMap;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measureHeader();
    });
    return Stack(
      children: [
        // The real map runs edge to edge; the header floats on it.
        if (mountReal) ...[
          Positioned.fill(
            child: RealMapView(
              key: ValueKey('real-map-$_realMapAttempt'),
              accessToken: widget.mapboxAccessToken,
              badges: data.countyBadges,
              homeCountySlug: data.homeCounty?.slug,
              loadPlaces: widget.loadMapPlaces,
              topInset: _headerBottom + 20,
              onReady: () => setState(() => _realMap = _RealMapStatus.ready),
              onFailed: () => setState(() => _realMap = _RealMapStatus.failed),
              onOpenCounty: widget.onOpenCounty,
              onOpenPlace: widget.onOpenPlace,
              onRoute: widget.onRoute,
              onPlaceRoute: widget.onPlaceRoute,
            ),
          ),
          const MapHomeHeaderScrim(),
          // Opaque page background behind everything until the real map's
          // style is up (so its blank canvas never flashes) or whenever
          // it's not the map being shown at all — covering the header
          // area too, which the drawn map's own layer below can't reach.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: showRealMap ? 0 : 1,
                duration: _fade,
                child: const ColoredBox(color: AppColors.pageBackground),
              ),
            ),
          ),
        ],
        MapHomeBoardTop(
          data: data,
          headerKey: _headerKey,
          fade: _fade,
          isMapInteracting: _isMapInteracting,
          onOpenProfile: widget.onOpenProfile,
          showRealMap: showRealMap,
          drawnMap: mapHomeDrawnMapFor(
            data,
            realLoading: waitingOnRealMap,
            onOpenCounty: widget.onOpenCounty,
            onInteractingChanged: (interacting) {
              if (interacting == _isMapInteracting) return;
              setState(() => _isMapInteracting = interacting);
            },
          ),
          showOfflineChip:
              data != null &&
              _realMapAllowed &&
              _realMap == _RealMapStatus.failed,
          onRetryRealMap: () => setState(() {
            _realMap = _RealMapStatus.loading;
            _realMapAttempt++;
            _isMapInteracting = false;
          }),
        ),
        // Always on top of both map layers (even when the drawn map is
        // covering RealMapView's own controls underneath), so the user
        // can get back to whichever map they're not currently viewing.
        if (mountReal)
          Positioned(
            top: _headerBottom + 20 + 8 + (_preferDrawnMap ? 0 : 3 * 48),
            right: 16,
            child: RealMapRoundButton(
              icon: _preferDrawnMap ? Icons.public : Icons.map_outlined,
              tooltip: _preferDrawnMap
                  ? 'Switch to live map'
                  : 'Switch to simple map',
              active: _preferDrawnMap,
              onPressed: () => _setPreferDrawnMap(!_preferDrawnMap),
            ),
          ),
        MapHomeBoardSheet(
          data: data,
          layout: _layout,
          fade: _fade,
          tripsNear: widget.tripsNear,
          savedPlans: widget.savedPlans,
          loadPlaces: widget.loadMapPlaces,
          recordTripCard: widget.recordTripCard,
          recordTripCardHeight: widget.recordTripCardHeight,
          onStartTrip: widget.onStartTrip,
          onOpenCounty: widget.onOpenCounty,
          onOpenPlace: widget.onOpenPlace,
          onRoute: widget.onRoute,
          onPromotedPlaceRoute: widget.onPromotedPlaceRoute,
          onSeeAllUnclaimed: widget.onSeeAllUnclaimed,
        ),
      ],
    );
  }
}

enum _RealMapStatus { loading, ready, failed }
