part of 'journey_replay_timeline.dart';

abstract class _JourneyReplayTimelineStateBase
    extends ConsumerState<JourneyReplayTimeline> {
  // Keyed by (index, kind, photo id) rather than index alone: several
  // moments can share a route point (a photo taken exactly where a
  // county is crossed, say) - and, per [JourneyMoments._photos]'s own
  // doc comment, several *photos* can share one too (a phone sitting at
  // one GPS fix while several are taken), which (index, kind) alone
  // can't tell apart. Each still needs its own stable GlobalKey.
  final _rowKeys = <(int, JourneyMomentKind, String?), GlobalKey>{};

  (int, JourneyMomentKind, String?) _keyTuple(JourneyMoment moment) =>
      (moment.index, moment.kind, moment.photo?.id);

  // Computed once, not on every rebuild - the route's endpoints never
  // change. Only good enough to label the empty-timeline's start/end
  // pins ("Started in Nairobi"); not a replacement for a real
  // reverse-geocoded place name.
  late final String? _startCounty = _countyAt(
    widget.points.isEmpty ? null : widget.points.first,
  );
  late final String? _endCounty = _countyAt(
    widget.points.isEmpty ? null : widget.points.last,
  );

  /// True while a batch of photos (manually picked, or camera-roll
  /// matches) is being saved and uploaded - shared by every "add" action
  /// on the empty-timeline card, since only one can run at a time anyway.
  bool _addingPhotos = false;

  bool _cameraRollScanStarted = false;
  _CameraRollScan _cameraRollScan = const _CameraRollScan(
    _CameraRollStatus.idle,
  );

  /// Photo ids already handed to [precacheImage] - a Trip's photo moments
  /// don't change while Replay is open, so this is only ever a one-time
  /// cost per photo rather than something repeated on every rebuild.
  final _precachedPhotoIds = <String>{};

  /// Rebuilds the open Trip media sheet in place when its inputs change
  /// (media, scan result, add-in-progress). Null while no sheet is open.
  StateSetter? _sheetSetState;

  void _refreshSheet() => _sheetSetState?.call(() {});

  /// True once the user closes the camera-roll suggestion in the sheet.
  bool _matchesDismissed = false;

  /// This account's per-Trip photo limit; null until read (or offline).
  JourneyMediaLimit? _mediaLimit;

  static String? _countyAt(JourneyPoint? point) {
    if (point == null) return null;
    final code = CountyBoundaryResolver.countyCodeFor(
      latitude: point.latitude,
      longitude: point.longitude,
      minimumInsideDistanceMeters:
          CountyBoundaryResolver.boundaryHysteresisMeters,
    );
    if (code == null) return null;
    for (final county in CountyPaths.all) {
      if (county.code == code) return county.name;
    }
    return null;
  }
}

mixin _JourneyReplayTimelineStateBehavior
    on _JourneyReplayTimelineStateBase, _JourneyReplayTimelineActions {
  @override
  void initState() {
    super.initState();
    unawaited(_loadMediaLimit());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _precachePhotos();
    });
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _refreshSheet();
  }

  GlobalKey _keyFor(JourneyMoment moment) =>
      _rowKeys.putIfAbsent(_keyTuple(moment), GlobalKey.new);

  @override
  void didUpdateWidget(JourneyReplayTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshSheet();
    });
    if (!identical(oldWidget.moments, widget.moments)) {
      _precachePhotos();
    }
    if (widget.currentMoments.isEmpty ||
        identical(oldWidget.currentMoments, widget.currentMoments)) {
      return;
    }
    final current = widget.currentMoments.first;
    final targetContext = _rowKeys[_keyTuple(current)]?.currentContext;
    if (targetContext == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!targetContext.mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
          alignment: 0.15,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watched here, once, rather than inside each row - the batched query
    // covers every crossing in the Trip at once either way, so there's no
    // per-row cost to sharing one result.
    final countyFacts =
        ref.watch(journeyCountyMomentFactsProvider(widget.summary.id)).value ??
        const <int, JourneyCountyMomentFacts>{};
    final currentIndex = widget.currentMoments.isEmpty
        ? null
        : widget.currentMoments.first.index;
    final showEmptyBody = widget.moments.isEmpty;
    // Auto-scan only until the first photo exists. The permanent media panel
    // below remains available for manual additions and review either way.
    final hasPhotos = widget.moments.any((moment) => moment.isPhoto);
    if (!hasPhotos && !widget.momentsLoading) {
      _ensureCameraRollScanStarted();
    }
    final momentCount = showEmptyBody ? 0 : widget.moments.length;
    // Index 0 is always the header (date/title/empty-body card); then one
    // item per moment. A single flat,
    // lazily-built ListView rather than a CustomScrollView of grouped
    // slivers (SliverMainAxisGroup) - that combination, with this list's
    // GlobalKey-keyed rows, was tripping a Flutter framework semantics
    // assertion ('!semantics.parentDataDirty') while the screen's
    // ticker-driven map/scrubber rebuilt nearby. ListView.builder is the
    // standard, well-tested virtualization path and keeps the same lazy,
    // don't-build-offscreen-photos behavior.
    final itemCount = 1 + momentCount;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          20,
          widget.topPadding,
          20,
          widget.bottomPadding,
        ),
        itemCount: itemCount,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dateRange(
                              widget.summary.startedAt,
                              widget.summary.endedAt,
                            ),
                            style: AppTypeScale.meta.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.summary.title,
                            style: AppTypeScale.sectionTitle.copyWith(
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!showEmptyBody)
                      _TripMediaButton(
                        count: widget.media.length,
                        hasMatches:
                            !_matchesDismissed &&
                            _cameraRollScan.status ==
                                _CameraRollStatus.matchesFound,
                        onPressed: _openTripMedia,
                      ),
                  ],
                ),
                if (!widget.summary.isUploaded) ...[
                  const SizedBox(height: 4),
                  Text(
                    'On this phone, waiting to upload to your account.',
                    style: AppTypeScale.small.copyWith(
                      color: AppColors.pendingFill,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (showEmptyBody)
                  _EmptyTimelineBody(
                    loading: widget.momentsLoading,
                    startedAt: widget.summary.startedAt,
                    endedAt: widget.summary.endedAt,
                    startCounty: _startCounty,
                    endCounty: _endCounty,
                    addingPhotos: _addingPhotos,
                    onAddPhotosManually: _addPhotosManually,
                    cameraRoll: _cameraRollScan,
                    onFindPhotos: _requestCameraRollAccess,
                    onAddAllMatches: _addAllMatches,
                    onChooseMatches: _chooseMatches,
                  ),
              ],
            );
          }
          final bodyIndex = i - 1;
          if (bodyIndex < momentCount) {
            final moment = widget.moments[bodyIndex];
            return KeyedSubtree(
              key: _keyFor(moment),
              child: JourneyTimelineMomentRow(
                moment: moment,
                time: _timeAt(moment.index),
                isCurrent: moment.index == currentIndex,
                isLast: bodyIndex == momentCount - 1,
                onTap: () => widget.onJumpTo(moment.index),
                countyFacts: moment.countyCode == null
                    ? null
                    : countyFacts[moment.countyCode],
                onOpenCounty:
                    widget.onOpenCounty == null || moment.countyCode == null
                    ? null
                    : () => widget.onOpenCounty!(moment.countyCode!),
                onDeletePhoto: _removePhoto,
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  DateTime? _timeAt(int index) => index >= 0 && index < widget.points.length
      ? widget.points[index].recordedAt
      : null;
}

class _JourneyReplayTimelineState extends _JourneyReplayTimelineStateBase
    with _JourneyReplayTimelineActions, _JourneyReplayTimelineStateBehavior {}
