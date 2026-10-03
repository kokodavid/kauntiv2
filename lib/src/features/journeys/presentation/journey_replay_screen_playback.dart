part of 'journey_replay_screen.dart';

mixin _JourneyReplayPlayback on _PlayerStateBase {
  late final Ticker _ticker = createTicker(_onTick);
  late List<JourneyMapMoment> _pins;
  bool get _playing => _ticker.isActive;

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
    } else {
      _positionController.value = next;
    }
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

  void _scrub(double value) {
    // The scrubber's drag gesture calls this continuously, many times a
    // second - once play/pause and the "active" flag are already settled
    // for this drag, later calls only need to move the position
    // notifier, not rebuild the whole screen on every pixel of movement.
    final needsFullRebuild = _playing || !_active || _showing.isNotEmpty;
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
    _ticker.dispose();
    _enterController.dispose();
    _positionController.dispose();
    super.dispose();
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
                child: AnimatedBuilder(
                  animation: _positionController,
                  builder: (context, _) {
                    final position = _position;
                    final index = position.floor().clamp(0, _track.lastIndex);
                    return JourneyRouteMap(
                      route: widget.route,
                      played: _active ? _playedUpTo(index) : null,
                      start: _JourneyReplayPlayback._at(points.first),
                      end: _active
                          ? null
                          : _JourneyReplayPlayback._at(points.last),
                      moments: _pins,
                      currentIndex: index,
                      marker: _active ? _track.positionAt(position) : null,
                      follow: _active,
                      animateFollow: false,
                      bottomInset: overlap,
                      pulsing: _showing.isNotEmpty,
                    );
                  },
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
                  onOpenCounty: widget.onOpenCounty,
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
              // Only a Trip that's actually uploaded has (or could have)
              // synced photos to build a share image from - one still
              // waiting to upload gets no share entry point here.
              if (widget.summary.isUploaded)
                JourneyMapButton(
                  alignment: Alignment.topRight,
                  onPressed: () => showTripShareSheet(
                    context,
                    summary: widget.summary,
                    route: widget.route,
                  ),
                  tooltip: 'Share this Trip',
                  // The reference's own upload-arrow-and-tray glyph
                  // (Claude-Design "Share Sheet 3a") rather than
                  // [Icons.ios_share_rounded] - see AppGlyphPaths.share.
                  iconWidget: const AppGlyphIcon(
                    path: AppGlyphPaths.share,
                    size: 20,
                    color: AppColors.foreground,
                  ),
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
                  child: AnimatedBuilder(
                    animation: _positionController,
                    builder: (context, _) => JourneyReplayPlaybackBar(
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
              ),
            ],
          );
        },
      ),
    );
  }
}
