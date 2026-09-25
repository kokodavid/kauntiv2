import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/journey_point.dart';
import '../domain/journey_replay.dart';
import '../domain/journey_route.dart';
import 'journey_route_map.dart';

/// A past Journey's map with replay: play / pause, a scrubber to drag to
/// any moment, 1× / 2× / 4× speed and a live "time · distance" readout.
/// Until replay starts it shows the whole route with start and end pins;
/// while replaying the route draws from the start with the camera on the
/// marker.
class JourneyReplayPanel extends StatefulWidget {
  const JourneyReplayPanel({super.key, required this.route});

  final JourneyRoute route;

  @override
  State<JourneyReplayPanel> createState() => _JourneyReplayPanelState();
}

class _JourneyReplayPanelState extends State<JourneyReplayPanel> {
  static const _frame = Duration(milliseconds: 50);

  late final JourneyReplayTrack _track = JourneyReplayTrack(widget.route);
  Timer? _timer;

  /// Position along the track in points (fractional while playing).
  double _position = 0;
  JourneyReplaySpeed _speed = JourneyReplaySpeed.x1;

  /// Replay has been started or scrubbed; false shows the whole route.
  bool _active = false;

  bool get _playing => _timer != null;
  int get _index => _position.floor().clamp(0, _track.lastIndex);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play() {
    if (_position >= _track.lastIndex) _position = 0;
    setState(() => _active = true);
    _timer = Timer.periodic(_frame, (_) {
      if (!mounted) return;
      final step =
          _track.pointsPerSecond(_speed) * _frame.inMilliseconds / 1000;
      setState(() {
        _position = (_position + step).clamp(0, _track.lastIndex.toDouble());
        if (_position >= _track.lastIndex) _pause();
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
  }

  void _togglePlay() => _playing ? setState(_pause) : _play();

  void _scrub(double value) => setState(() {
    _pause();
    _active = true;
    _position = value;
  });

  void _showWholeRoute() => setState(() {
    _pause();
    _active = false;
    _position = 0;
  });

  JourneyLatLng _at(JourneyPoint p) =>
      (latitude: p.latitude, longitude: p.longitude);

  @override
  Widget build(BuildContext context) {
    final points = _track.points;
    final index = _index;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 320,
            child: JourneyRouteMap(
              route: _active ? _track.routeUpTo(index) : widget.route,
              start: _at(points.first),
              end: _active ? null : _at(points.last),
              marker: _active ? _at(points[index]) : null,
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
                child: Text(
                  '${JourneyFormat.clock(_track.elapsedAt(index))} · '
                  '${JourneyFormat.distance(_track.distanceAt(index))}',
                  style: AppTypeScale.itemTitle,
                ),
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
