import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/journey_point.dart';
import '../domain/journey_replay.dart';
import '../domain/journey_route.dart';
import 'journey_route_map.dart';

/// A past Journey's map with replay: play / pause, a scrubber to drag to
/// any moment, 1× / 2× / 4× speed and a live "time · distance" readout.
/// Until replay starts it shows the whole route with start and end pins.
/// While replaying, the marker glides between points every screen frame,
/// the played part draws over a faded full route and the camera rides
/// with the marker.
class JourneyReplayPanel extends StatefulWidget {
  const JourneyReplayPanel({super.key, required this.route});

  final JourneyRoute route;

  @override
  State<JourneyReplayPanel> createState() => _JourneyReplayPanelState();
}

class _JourneyReplayPanelState extends State<JourneyReplayPanel>
    with SingleTickerProviderStateMixin {
  late final JourneyReplayTrack _track = JourneyReplayTrack(widget.route);
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;

  /// Position along the track in points, fractional between them.
  double _position = 0;
  JourneyReplaySpeed _speed = JourneyReplaySpeed.x1;

  /// Replay has been started or scrubbed; false shows the whole route.
  bool _active = false;

  /// The played part, rebuilt only when the replay passes a point.
  JourneyRoute? _played;
  int _playedIndex = -1;

  bool get _playing => _ticker.isActive;
  int get _index => _position.floor().clamp(0, _track.lastIndex);

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final seconds = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    setState(() {
      _position = (_position + _track.pointsPerSecond(_speed) * seconds)
          .clamp(0, _track.lastIndex.toDouble());
      if (_position >= _track.lastIndex) _ticker.stop();
    });
  }

  void _play() {
    if (_position >= _track.lastIndex) _position = 0;
    _lastTick = Duration.zero;
    setState(() => _active = true);
    _ticker.start();
  }

  void _togglePlay() => _playing ? setState(_ticker.stop) : _play();

  void _scrub(double value) => setState(() {
    _ticker.stop();
    _active = true;
    _position = value;
  });

  void _showWholeRoute() => setState(() {
    _ticker.stop();
    _active = false;
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

  JourneyLatLng _at(JourneyPoint p) =>
      (latitude: p.latitude, longitude: p.longitude);

  @override
  Widget build(BuildContext context) {
    final points = _track.points;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 320,
            child: JourneyRouteMap(
              route: widget.route,
              played: _active ? _playedUpTo(_index) : null,
              start: _at(points.first),
              end: _active ? null : _at(points.last),
              marker: _active ? _track.positionAt(_position) : null,
              follow: _active,
              animateFollow: false,
            ),
          ),
        ),
        if (_track.canReplay) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.filled(
                onPressed: _togglePlay,
                tooltip: _playing ? 'Pause replay' : 'Play replay',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.accentForeground,
                ),
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              ),
              Expanded(
                child: Slider(
                  value: _position,
                  max: _track.lastIndex.toDouble(),
                  activeColor: AppColors.accent,
                  onChanged: _scrub,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(_readout, style: AppTypeScale.itemTitle),
              ),
              for (final speed in JourneyReplaySpeed.values)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    label: Text(speed.label),
                    selected: speed == _speed,
                    onSelected: (_) => setState(() => _speed = speed),
                    selectedColor: AppColors.accent,
                    labelStyle: AppTypeScale.pill.copyWith(
                      color: speed == _speed
                          ? AppColors.accentForeground
                          : AppColors.foreground,
                    ),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          if (_active)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _showWholeRoute,
                child: const Text('Show whole route'),
              ),
            ),
        ],
      ],
    );
  }
}
