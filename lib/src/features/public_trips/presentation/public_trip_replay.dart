import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/map/replay_map_types.dart';
import '../../../core/map/replay_route_map.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/replay_controls.dart';
import '../../../core/widgets/replay_layout.dart';
import '../../../core/widgets/replay_playback_bar.dart';
import '../../../core/widgets/replay_stat_bar.dart';
import '../domain/public_trip_track.dart';
import '../domain/public_trip_view.dart';
import 'public_trip_format.dart';
import 'public_trip_replay_path.dart';
import 'public_trip_screen_body.dart';

/// A public trip in the same design as the owner's replay: the map on top,
/// the story below, and a floating transport bar. Playback is illustrative,
/// an even pace along the shared route, because the real times are never
/// shared.
class PublicTripReplay extends StatefulWidget {
  const PublicTripReplay({
    super.key,
    required this.trip,
    required this.onReport,
    required this.onBlock,
    this.onOpenDirections,
  });

  final PublicTripView trip;
  final OpenPublicTripDirections? onOpenDirections;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  @override
  State<PublicTripReplay> createState() => _PublicTripReplayState();
}

class _PublicTripReplayState extends State<PublicTripReplay>
    with TickerProviderStateMixin {
  late final PublicTripTrack _track = PublicTripTrack(widget.trip.routeLines);
  late final PublicTripReplayPath _route = PublicTripReplayPath(_track.lines);
  late final List<ReplayMapMoment> _pins = _buildPins();
  late final List<int> _ticks = [for (final pin in _pins) pin.index];
  late final Ticker _ticker = createTicker(_onTick);
  late final AnimationController _position = AnimationController(
    vsync: this,
    upperBound: _track.lastIndex.toDouble(),
  );
  Duration _lastTick = Duration.zero;
  PublicTripSpeed _speed = PublicTripSpeed.x1;
  bool _active = false;
  int _playedIndex = -1;
  PublicTripReplayPath? _played;

  bool get _playing => _ticker.isActive;

  List<ReplayMapMoment> _buildPins() {
    if (!_track.canReplay) return const [];
    return [
      for (final moment in widget.trip.moments)
        (
          at: (latitude: moment.latitude, longitude: moment.longitude),
          kind: ReplayMomentKind.note,
          index: _track.nearestIndex(moment.latitude, moment.longitude),
        ),
      for (final photo in widget.trip.photos)
        if (photo.hasPlace)
          (
            at: (latitude: photo.latitude!, longitude: photo.longitude!),
            kind: ReplayMomentKind.photo,
            index: _track.nearestIndex(photo.latitude!, photo.longitude!),
          ),
    ];
  }

  @override
  void dispose() {
    _ticker.dispose();
    _position.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final seconds = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    final next = (_position.value + _track.pointsPerSecond(_speed) * seconds)
        .clamp(0, _track.lastIndex)
        .toDouble();
    if (next >= _track.lastIndex) {
      // Only the end needs a rebuild (the play button flips back).
      setState(() {
        _position.value = next;
        _ticker.stop();
      });
    } else {
      _position.value = next;
    }
  }

  void _togglePlay() {
    if (!_track.canReplay) return;
    if (_playing) {
      setState(_ticker.stop);
      return;
    }
    if (_position.value >= _track.lastIndex) _position.value = 0;
    _lastTick = Duration.zero;
    setState(() => _active = true);
    unawaited(_ticker.start());
  }

  void _scrub(double value) {
    final needsRebuild = _playing || !_active;
    _ticker.stop();
    _position.value = value;
    if (needsRebuild) setState(() => _active = true);
  }

  void _cycleSpeed() => setState(() => _speed = _speed.next);

  void _showWholeRoute() => setState(() {
    _ticker.stop();
    _active = false;
    _position.value = 0;
  });

  PublicTripReplayPath _playedUpTo(int index) {
    if (index != _playedIndex || _played == null) {
      _played = PublicTripReplayPath(_track.linesUpTo(index));
      _playedIndex = index;
    }
    return _played!;
  }

  String get _readout {
    final done = publicTripDistanceLabel(_track.distanceAt(_position.value));
    return '$done of ${publicTripDistanceLabel(_track.totalMeters)}';
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return ReplayLayout(
      mapBuilder: (context, bottomInset) => AnimatedBuilder(
        animation: _position,
        builder: (context, _) {
          final position = _position.value;
          final index = position.floor().clamp(0, _track.lastIndex);
          return ReplayRouteMap(
            route: _route,
            played: _active ? _playedUpTo(index) : null,
            start: trip.publicStart == null
                ? null
                : (
                    latitude: trip.publicStart!.latitude,
                    longitude: trip.publicStart!.longitude,
                  ),
            moments: _pins,
            currentIndex: index,
            marker: _active && _track.canReplay
                ? _track.positionAt(position)
                : null,
            follow: _active,
            animateFollow: false,
            bottomInset: bottomInset,
          );
        },
      ),
      bodyBuilder: (context, top, bottom) => PublicTripScreenBody(
        trip: trip,
        onOpenDirections: widget.onOpenDirections,
        onReport: widget.onReport,
        onBlock: widget.onBlock,
        topPadding: top,
        bottomPadding: bottom,
      ),
      statBar: ReplayStatBar(
        stats: [
          (
            value: publicTripDistanceLabel(trip.distanceMeters),
            label: 'DISTANCE',
          ),
          (value: '${trip.counties.length}', label: 'COUNTIES'),
          if (trip.photos.isNotEmpty)
            (value: '${trip.photos.length}', label: 'PHOTOS'),
        ],
      ),
      overlays: [
        // The app's own back button, kept its natural size by Positioned.
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
              child: AppBackButton(
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ),
        if (_active) ReplayWholeRoutePill(onPressed: _showWholeRoute),
      ],
      playbackBar: !_track.canReplay
          ? const SizedBox.shrink()
          : AnimatedBuilder(
              animation: _position,
              builder: (context, _) => ReplayPlaybackBar(
                playing: _playing,
                pausedAtMoment: false,
                position: _position.value,
                lastIndex: _track.lastIndex,
                tickIndices: _ticks,
                readout: _readout,
                speedLabel: _speed.label,
                onTogglePlay: _togglePlay,
                onScrub: _scrub,
                onCycleSpeed: _cycleSpeed,
              ),
            ),
    );
  }
}
