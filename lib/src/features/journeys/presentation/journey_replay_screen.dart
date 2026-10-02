import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../application/journey_key_moments.dart';
import '../application/journey_views.dart';
import '../domain/journey_moments.dart';
import '../domain/journey_point.dart';
import '../domain/journey_replay.dart';
import '../domain/journey_route.dart';
import '../domain/journey_summary.dart';
import 'journey_replay_controls.dart';
import 'journey_replay_playback_bar.dart';
import 'journey_replay_stat_bar.dart';
import 'journey_replay_timeline.dart';
import 'journey_route_map.dart';

/// A past Journey as a scrollable story: the map at the top sets the
/// scene, a timeline of its key moments tells it below, and a floating
/// transport bar drives the replay through both.
class JourneyReplayScreen extends ConsumerWidget {
  const JourneyReplayScreen({super.key, required this.journeyId});

  final String journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(journeyDetailProvider(journeyId));
    final momentsAsync = ref.watch(journeyMomentsProvider(journeyId));
    final moments = momentsAsync.value;
    // True only while moments has never resolved yet - a refresh that
    // already has a cached value (isLoading alongside hasValue) shouldn't
    // re-trigger the loader, only this Trip's very first computation.
    final momentsLoading = momentsAsync.isLoading && !momentsAsync.hasValue;
    final value = detail.value;
    final route = value?.route;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: route != null && route.pointCount > 1
          ? _Player(
              summary: value!.summary,
              route: route,
              moments: moments ?? const [],
              momentsLoading: momentsLoading,
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: switch (detail) {
                    AsyncValue(:final error?) => JourneyReplayMessage(
                      text: error is JourneyNotFound
                          ? 'This Trip was deleted.'
                          : "Couldn't load this Trip. Check your "
                                'connection.',
                      onRetry: error is JourneyNotFound
                          ? null
                          : () => ref.invalidate(
                              journeyDetailProvider(journeyId),
                            ),
                    ),
                    AsyncValue(hasValue: true) => const JourneyReplayMessage(
                      text:
                          'Not enough route points were recorded to '
                          'show this Trip.',
                    ),
                    _ => const CircularProgressIndicator(strokeWidth: 2),
                  },
                ),
                JourneyMapButton(
                  alignment: Alignment.topLeft,
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Close replay',
                  icon: Icons.close,
                ),
              ],
            ),
    );
  }
}

class _Player extends StatefulWidget {
  const _Player({
    required this.summary,
    required this.route,
    required this.moments,
    required this.momentsLoading,
  });

  final JourneySummary summary;
  final JourneyRoute route;
  final List<JourneyMoment> moments;

  /// Forwarded to [JourneyReplayTimeline] so it can show a loading
  /// indicator instead of "No key moments on this Trip yet." while
  /// `journeyMomentsProvider` is still computing its first value.
  final bool momentsLoading;

  @override
  State<_Player> createState() => _PlayerState();
}

class _PlayerState extends State<_Player> with TickerProviderStateMixin {
  late final JourneyReplayTrack _track = JourneyReplayTrack(widget.route);
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;

  /// A one-shot fade/slide as the replay screen first appears, rather than
  /// the map and timeline just popping in.
  late final AnimationController _enterController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();
  late final CurvedAnimation _enterCurve = CurvedAnimation(
    parent: _enterController,
    curve: Curves.easeOut,
  );

  /// Position along the track in points, fractional between them.
  double _position = 0;
  JourneyReplaySpeed _speed = JourneyReplaySpeed.x1;

  /// Replay has been started, scrubbed or jumped to; false shows the
  /// whole route.
  bool _active = false;

  /// The key moments replay is currently paused at, lighting up in the
  /// timeline; empty while it plays.
  List<JourneyMoment> _showing = const [];

  /// The played part, rebuilt only when the replay passes a point.
  JourneyRoute? _played;
  int _playedIndex = -1;

  late List<JourneyLatLng> _pins = _pinsFor(widget.moments);

  bool get _playing => _ticker.isActive;
  int get _index => _position.floor().clamp(0, _track.lastIndex);

  @override
  void didUpdateWidget(_Player oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.moments, widget.moments)) {
      _pins = _pinsFor(widget.moments);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _enterController.dispose();
    super.dispose();
  }

  /// A pin per moment point on the route.
  List<JourneyLatLng> _pinsFor(List<JourneyMoment> moments) => [
    for (final index in {for (final m in moments) m.index})
      if (index <= _track.lastIndex) _at(_track.points[index]),
  ];

  void _onTick(Duration elapsed) {
    final seconds = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    setState(() {
      var next = (_position + _track.pointsPerSecond(_speed) * seconds)
          .clamp(0, _track.lastIndex)
          .toDouble();
      final stop = JourneyMoments.nextStopAfter(_position, widget.moments);
      if (stop != null && stop < _track.lastIndex && next >= stop) {
        next = stop.toDouble();
        _showing = JourneyMoments.at(stop, widget.moments);
        _ticker.stop();
      }
      _position = next;
      if (_position >= _track.lastIndex) _ticker.stop();
    });
  }

  void _play() {
    if (_position >= _track.lastIndex) _position = 0;
    _lastTick = Duration.zero;
    setState(() {
      _active = true;
      _showing = const [];
    });
    unawaited(_ticker.start());
  }

  void _togglePlay() => _playing ? setState(_ticker.stop) : _play();

  void _scrub(double value) => setState(() {
    _ticker.stop();
    _active = true;
    _showing = const [];
    _position = value;
  });

  /// Jumps replay to a moment's point, lighting it up immediately - "tap
  /// any moment to jump the map there".
  void _jumpTo(int index) => setState(() {
    _ticker.stop();
    _active = true;
    _position = index.toDouble();
    _showing = JourneyMoments.at(index, widget.moments);
  });

  /// Cycles 1x -> 2x -> 4x -> 1x with one tap, rather than three chips.
  void _cycleSpeed() => setState(() {
    final values = JourneyReplaySpeed.values;
    _speed = values[(values.indexOf(_speed) + 1) % values.length];
  });

  void _showWholeRoute() => setState(() {
    _ticker.stop();
    _active = false;
    _showing = const [];
    _position = 0;
  });

  JourneyRoute _playedUpTo(int index) {
    if (index != _playedIndex || _played == null) {
      _played = _track.routeUpTo(index);
      _playedIndex = index;
    }
    return _played!;
  }

  /// "0:12:40 · 3.2 km" at the marker.
  String get _readout {
    final time = JourneyFormat.clock(_track.elapsedAtPosition(_position));
    final distance = _track.distanceAtPosition(_position);
    return '$time · ${JourneyFormat.distance(distance)}';
  }

  static JourneyLatLng _at(JourneyPoint p) =>
      (latitude: p.latitude, longitude: p.longitude);

  @override
  Widget build(BuildContext context) {
    final points = _track.points;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return FadeTransition(
      opacity: _enterCurve,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mapHeight = (constraints.maxHeight * 0.42).clamp(260.0, 420.0);
          const overlap = 32.0;
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: mapHeight,
                child: JourneyRouteMap(
                  route: widget.route,
                  played: _active ? _playedUpTo(_index) : null,
                  start: _at(points.first),
                  end: _active ? null : _at(points.last),
                  pins: _pins,
                  marker: _active ? _track.positionAt(_position) : null,
                  follow: _active,
                  animateFollow: false,
                  bottomInset: overlap,
                  pulsing: _showing.isNotEmpty,
                ),
              ),
              Positioned.fill(
                top: mapHeight,
                child: JourneyReplayTimeline(
                  summary: widget.summary,
                  points: points,
                  moments: widget.moments,
                  momentsLoading: widget.momentsLoading,
                  currentMoments: _showing,
                  onJumpTo: _jumpTo,
                  topPadding: overlap + 16,
                  bottomPadding: 104 + safeBottom,
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: mapHeight - overlap,
                child: JourneyReplayStatBar(
                  distanceMeters:
                      widget.summary.distanceMeters ??
                      widget.route.distanceMeters,
                  averageSpeedMps: widget.summary.averageSpeedMps,
                  topSpeedMps: widget.summary.topSpeedMps,
                  highestElevationMeters: widget.summary.highestElevationMeters,
                ),
              ),
              JourneyMapButton(
                alignment: Alignment.topLeft,
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Close replay',
                icon: Icons.close,
              ),
              if (_active) JourneyWholeRoutePill(onPressed: _showWholeRoute),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12 + safeBottom,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(_enterCurve),
                  child: JourneyReplayPlaybackBar(
                    playing: _playing,
                    pausedAtMoment: _showing.isNotEmpty,
                    position: _position,
                    lastIndex: _track.lastIndex,
                    moments: widget.moments,
                    readout: _readout,
                    speed: _speed,
                    onTogglePlay: _togglePlay,
                    onScrub: _scrub,
                    onCycleSpeed: _cycleSpeed,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
