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
import 'journey_moment_row.dart';
import 'journey_replay_controls.dart';
import 'journey_route_map.dart';

/// A past Journey on a full-screen map with floating replay controls.
/// Replay pauses at key moments before continuing.
class JourneyReplayScreen extends ConsumerWidget {
  const JourneyReplayScreen({
    super.key,
    required this.journeyId,
    this.onOpenPlace,
  });

  final String journeyId;

  /// Opens Place Detail from a place moment (null without Supabase).
  final OpenJourneyPlace? onOpenPlace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(journeyDetailProvider(journeyId));
    final moments = ref.watch(journeyMomentsProvider(journeyId)).value;
    final value = detail.value;
    final route = value?.route;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      // Expand: the map fills the screen, not just the close button's box.
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: route != null && route.pointCount > 1
                ? _Player(
                    summary: value!.summary,
                    route: route,
                    moments: moments ?? const [],
                    onOpenPlace: onOpenPlace,
                  )
                : Center(
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
    this.onOpenPlace,
  });

  final JourneySummary summary;
  final JourneyRoute route;
  final List<JourneyMoment> moments;
  final OpenJourneyPlace? onOpenPlace;

  @override
  State<_Player> createState() => _PlayerState();
}

class _PlayerState extends State<_Player> with TickerProviderStateMixin {
  /// Room the camera leaves for the floating summary and controls.
  static const _controlsInset = 250.0;

  late final JourneyReplayTrack _track = JourneyReplayTrack(widget.route);
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;

  /// A one-shot fade/slide as the replay screen first appears, rather than
  /// the map and controls just popping in.
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

  /// Replay has been started or scrubbed; false shows the whole route.
  bool _active = false;

  /// The key moments replay has paused at.
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

  /// A pin per moment point on the route; places pinned where they are.
  List<JourneyLatLng> _pinsFor(List<JourneyMoment> moments) => [
    for (final index in {
      for (final m in moments)
        if (!m.isPlace) m.index,
    })
      if (index <= _track.lastIndex) _at(_track.points[index]),
    for (final m in moments)
      if (m.place case final place?)
        (latitude: place.latitude, longitude: place.longitude),
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: _enterCurve,
            child: JourneyRouteMap(
              route: widget.route,
              played: _active ? _playedUpTo(_index) : null,
              start: _at(points.first),
              end: _active ? null : _at(points.last),
              pins: _pins,
              marker: _active ? _track.positionAt(_position) : null,
              follow: _active,
              animateFollow: false,
              bottomInset: _controlsInset + safeBottom,
              pulsing: _showing.isNotEmpty,
            ),
          ),
        ),
        if (_active)
          JourneyMapButton(
            alignment: Alignment.topRight,
            onPressed: _showWholeRoute,
            tooltip: 'Show whole route',
            icon: Icons.zoom_out_map,
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.all(12),
            child: FadeTransition(
              opacity: _enterCurve,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(_enterCurve),
                child: JourneyReplayControls(
                  summary: widget.summary,
                  distanceMeters:
                      widget.summary.distanceMeters ??
                      widget.route.distanceMeters,
                  playing: _playing,
                  position: _position,
                  lastIndex: _track.lastIndex,
                  readout: _readout,
                  speed: _speed,
                  moments: _showing,
                  momentTime: _showing.isEmpty
                      ? null
                      : points[_showing.first.index].recordedAt,
                  onTogglePlay: _togglePlay,
                  onScrub: _scrub,
                  onSpeed: (speed) => setState(() => _speed = speed),
                  onOpenPlace: widget.onOpenPlace,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
