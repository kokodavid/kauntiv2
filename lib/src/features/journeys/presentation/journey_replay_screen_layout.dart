part of 'journey_replay_screen.dart';

mixin _JourneyReplayScreenLayout on _JourneyReplayPlayback {
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
              if (widget.summary.isUploaded)
                JourneyMapButton(
                  alignment: Alignment.topRight,
                  onPressed: () => showTripShareSheet(
                    context,
                    summary: widget.summary,
                    route: widget.route,
                    extrasBuilder: widget.shareExtrasBuilder,
                  ),
                  tooltip: 'Share this Trip',
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
