import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/map_place.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/trip_plan_view.dart';
import '../application/trip_planner_providers.dart';
import '../domain/trip_plan.dart';
import '../domain/trip_route.dart';
import 'trip_map_round_button.dart';
import 'trip_plan_map.dart';
import 'trip_plan_map_controller.dart';
import 'trip_plan_map_layers.dart';
import 'trip_plan_summary_card.dart';
import 'trip_start_button.dart';

/// The road plan in the handoff's immersive, interactive map layout.
///
/// The inline map is removed before this route is pushed. That leaves one
/// native Mapbox surface at a time, which avoids Android platform-view
/// composition failures while retaining pan, zoom, and marker interaction.
class TripPlanMapPage extends ConsumerStatefulWidget {
  const TripPlanMapPage({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    required this.onStart,
  });

  final String placeId;
  final String placeName;
  final double latitude;
  final double longitude;
  final Future<void> Function(BuildContext context, List<MapPlace> stops)
  onStart;

  static Future<void> open(
    BuildContext context, {
    required String placeId,
    required String placeName,
    required double latitude,
    required double longitude,
    required Future<void> Function(BuildContext context, List<MapPlace> stops)
    onStart,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => TripPlanMapPage(
        placeId: placeId,
        placeName: placeName,
        latitude: latitude,
        longitude: longitude,
        onStart: onStart,
      ),
    ),
  );

  @override
  ConsumerState<TripPlanMapPage> createState() => _TripPlanMapPageState();
}

class _TripPlanMapPageState extends ConsumerState<TripPlanMapPage> {
  final _controller = TripPlanMapController();
  final _cardKey = GlobalKey();
  Timer? _transitionFallback;
  Animation<double>? _routeAnimation;
  var _ready = false;
  var _collapsed = false;
  var _cardHeight = 330.0;
  int? _selected;
  String _framed = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready || _routeAnimation != null) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _ready = true;
      return;
    }
    _routeAnimation = animation..addStatusListener(_onRouteAnimation);
    _transitionFallback = Timer(const Duration(milliseconds: 900), () {
      if (mounted && !_ready) setState(() => _ready = true);
    });
  }

  void _onRouteAnimation(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteAnimation);
    _transitionFallback?.cancel();
    _controller.detach();
    super.dispose();
  }

  EdgeInsets get _padding => EdgeInsets.only(
    top: MediaQuery.paddingOf(context).top + 64,
    bottom: _cardHeight + MediaQuery.paddingOf(context).bottom + 36,
    left: 32,
    right: 32,
  );

  List<TripRoutePoint> _points(TripPlan? plan) =>
      plan?.route.points ?? [TripRoutePoint(widget.latitude, widget.longitude)];

  List<TripRoutePoint> _stops(TripPlan? plan) => [
    for (final stop in plan?.stops ?? const <MapPlace>[])
      TripRoutePoint(stop.lat, stop.lng),
  ];

  List<TripRoutePoint> _markers(TripPlan? plan) =>
      TripPlanMapLayers.markers(_points(plan), _stops(plan));

  void _afterLayout(TripPlan? plan) {
    final measured = _cardKey.currentContext?.size?.height;
    if (measured != null && (measured - _cardHeight).abs() >= 1) {
      setState(() => _cardHeight = measured);
      return;
    }
    _fit(plan);
  }

  void _fit(TripPlan? plan, {bool force = false}) {
    final signature = '${plan?.route.distanceMeters}-${_cardHeight.round()}';
    if ((!force && signature == _framed) || !_controller.attached) return;
    final first = _framed.isEmpty;
    _framed = signature;
    unawaited(
      _controller.fit(_points(plan), padding: _padding, animate: !first),
    );
  }

  void _select(int index, TripPlan? plan) {
    final markers = _markers(plan);
    if (index >= markers.length) return;
    setState(() => _selected = _selected == index ? null : index);
    if (_selected == null) {
      _fit(plan, force: true);
      return;
    }
    unawaited(_controller.focus(markers[index], padding: _padding));
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(
      tripPlanViewProvider(widget.placeId, widget.latitude, widget.longitude),
    );
    final claimed = ref.watch(claimedCountyCodesProvider).value ?? <int>{};
    final plan = snapshot.plan;
    final inset = MediaQuery.paddingOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _ready) _afterLayout(plan);
    });
    return Scaffold(
      backgroundColor: AppColors.lockedFill,
      body: Stack(
        children: [
          Positioned.fill(
            child: _ready
                ? TripPlanMap(
                    points: _points(plan),
                    stops: _stops(plan),
                    selected: _selected,
                    controller: _controller,
                    padding: _padding,
                    height: null,
                    rounded: false,
                    onMarkerTap: (index) => _select(index, plan),
                  )
                : const ColoredBox(
                    color: AppColors.lockedFill,
                    child: Center(
                      child: AppProgressIndicator(
                        color: AppColors.accent,
                        radius: 14,
                      ),
                    ),
                  ),
          ),
          Positioned(
            left: 12,
            top: inset.top + 10,
            child: AppBackButton(
              size: 44,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: inset.bottom + 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TripMapRoundButton(
                  icon: Icons.fit_screen_outlined,
                  tooltip: 'Fit route',
                  onPressed: () {
                    setState(() => _selected = null);
                    _fit(plan, force: true);
                  },
                ),
                const SizedBox(height: 8),
                TripMapRoundButton(
                  icon: Icons.my_location,
                  tooltip: 'My location',
                  onPressed: snapshot.origin == null
                      ? null
                      : () => unawaited(
                          _controller.focus(
                            snapshot.origin!,
                            padding: _padding,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                if (plan != null)
                  SizedBox(
                    width: double.infinity,
                    child: KeyedSubtree(
                      key: _cardKey,
                      child: TripPlanSummaryCard(
                        plan: plan,
                        destinationName: widget.placeName,
                        claimed: claimed,
                        collapsed: _collapsed,
                        onToggle: () =>
                            setState(() => _collapsed = !_collapsed),
                        selected: _selected,
                        onSelect: (index) => _select(index, plan),
                        startButton: TripStartButton(
                          placeId: widget.placeId,
                          latitude: widget.latitude,
                          longitude: widget.longitude,
                          onStart: widget.onStart,
                          compact: _collapsed,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
