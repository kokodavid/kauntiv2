part of 'journey_replay_screen.dart';

mixin _JourneyReplayPlayback on _PlayerStateBase {
  late final Ticker _ticker = createTicker(_onTick);
  late List<JourneyMapMoment> _pins;
  bool get _playing => _ticker.isActive;

  /// How long playback dwells on a moment before resuming on its own --
  /// long enough to glance at the photo/note, short enough that replaying
  /// a whole Trip doesn't need a tap at every stop.
  static const _momentPauseDuration = Duration(seconds: 3);

  /// Pending auto-resume from [_scheduleAutoResume], if any. Cancelled by
  /// every other way playback state can change (manual play/pause, scrub,
  /// jump, "show whole route", dispose) so it never fires into a state the
  /// user has already moved on from.
  Timer? _momentResumeTimer;

  /// A map pin per key moment - a photo moment or a "note" (every other
  /// [JourneyMomentKind]), each carrying its own point [JourneyMoment.index]
  /// so the map can colour it pending/passed against the playhead.
  List<JourneyMapMoment> _pinsFor(List<JourneyMoment> moments) => [
    for (final m in moments)
      if (m.index <= _track.lastIndex)
        (
          at: _JourneyReplayPlayback._at(_track.points[m.index]),
          kind: m.kind == JourneyMomentKind.photo
              ? JourneyMapMomentKind.photo
              : JourneyMapMomentKind.note,
          index: m.index,
        ),
  ];

  void _onTick(Duration elapsed) {
    final seconds = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    var next = (_position + _track.pointsPerSecond(_speed) * seconds)
        .clamp(0, _track.lastIndex)
        .toDouble();
    final stop = JourneyMoments.nextStopAfter(_position, widget.moments);
    final hitStop = stop != null && stop < _track.lastIndex && next >= stop;
    if (hitStop) next = stop.toDouble();
    final reachedEnd = next >= _track.lastIndex;
    if (hitStop || reachedEnd) {
      // A real state change beyond the raw position - pausing playback
      // and/or lighting up a moment in the timeline - needs setState so
      // the timeline and playback bar's play/pause icon pick it up. An
      // ordinary mid-flight tick only moves the frame driver, without
      // touching setState or rebuilding the rest of the screen.
      setState(() {
        _positionController.value = next;
        if (hitStop) _showing = JourneyMoments.at(stop, widget.moments);
        _ticker.stop();
      });
      // Only a moment-triggered pause resumes itself - reaching the end
      // of the Trip has nothing left to play into.
      if (hitStop) _scheduleAutoResume();
    } else {
      _positionController.value = next;
    }
  }

  /// Resumes playback on its own after [_momentPauseDuration], unless the
  /// user does something else with playback first.
  void _scheduleAutoResume() {
    _momentResumeTimer?.cancel();
    _momentResumeTimer = Timer(_momentPauseDuration, () {
      if (!mounted) return;
      _play();
    });
  }

  void _play() {
    _momentResumeTimer?.cancel();
    if (_position >= _track.lastIndex) _position = 0;
    _lastTick = Duration.zero;
    setState(() {
      _active = true;
      _showing = const [];
    });
    unawaited(_ticker.start());
  }

  void _togglePlay() {
    if (_playing) {
      _momentResumeTimer?.cancel();
      setState(_ticker.stop);
    } else {
      _play();
    }
  }

  void _scrub(double value) {
    // The scrubber's drag gesture calls this continuously, many times a
    // second - once play/pause and the "active" flag are already settled
    // for this drag, later calls only need to move the position
    // notifier, not rebuild the whole screen on every pixel of movement.
    final needsFullRebuild = _playing || !_active || _showing.isNotEmpty;
    _momentResumeTimer?.cancel();
    _ticker.stop();
    if (needsFullRebuild) {
      setState(() {
        _active = true;
        _showing = const [];
        _position = value;
      });
    } else {
      _position = value;
    }
  }

  /// Jumps replay to a moment's point, lighting it up immediately - "tap
  /// any moment to jump the map there".
  void _jumpTo(int index) => setState(() {
    _momentResumeTimer?.cancel();
    _ticker.stop();
    _active = true;
    _position = index.toDouble();
    _showing = JourneyMoments.at(index, widget.moments);
  });

  /// Cycles 1x -> 2x -> 4x -> 1x with one tap, rather than three chips.
  void _cycleSpeed() => setState(() {
    const values = JourneyReplaySpeed.values;
    _speed = values[(values.indexOf(_speed) + 1) % values.length];
  });

  void _showWholeRoute() => setState(() {
    _momentResumeTimer?.cancel();
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

  /// "0:12:40 · 3.2 km · 24 km/h" at the marker.
  String get _readout {
    final time = JourneyFormat.clock(_track.elapsedAtPosition(_position));
    final distance = _track.distanceAtPosition(_position);
    final speed = _track.speedAtPosition(_position);
    return '$time · ${JourneyFormat.distance(distance)} · '
        '${JourneyFormat.speed(speed)}';
  }

  @override
  void initState() {
    super.initState();
    _pins = _pinsFor(widget.moments);
    _positionController = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: _track.lastIndex.toDouble(),
      value: 0,
    );
  }

  @override
  void didUpdateWidget(_Player oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.moments, widget.moments)) {
      _pins = _pinsFor(widget.moments);
    }
  }

  @override
  void dispose() {
    _momentResumeTimer?.cancel();
    _ticker.dispose();
    _enterController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  static JourneyLatLng _at(JourneyPoint p) =>
      (latitude: p.latitude, longitude: p.longitude);
}
