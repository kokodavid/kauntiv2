part of 'journey_replay_timeline.dart';

mixin _JourneyReplayTimelineActions on _JourneyReplayTimelineStateBase {
  /// Decodes every photo moment's image up front, off the scroll path -
  /// by the time the user scrolls a photo row into view it's already in
  /// Flutter's image cache, instead of popping in only once it's visible.
  void _precachePhotos() {
    for (final moment in widget.moments) {
      final photo = moment.photo;
      if (photo == null || !_precachedPhotoIds.add(photo.id)) continue;
      unawaited(_precacheOne(photo));
    }
  }

  Future<void> _precacheOne(JourneyMediaItem photo) async {
    try {
      await precacheImage(
        appNetworkImage(photo.url, cacheKey: photo.id),
        context,
        onError: (error, stackTrace) {},
      );
    } on Object {
      // A failed precache just means the row's own Image.network fetches
      // it normally when it scrolls into view (and shows its own
      // errorBuilder if that fails too) - nothing to surface here.
    }
  }

  /// Kicks off the silent camera-roll check at most once per Trip:
  /// checked without prompting, so it never surprises the user with a
  /// permission dialog just for opening Replay. Only runs once this
  /// screen already knows the Trip has no photo moments of its own -
  /// whether or not it has other moments (stops, crossings, and so on).
  void _ensureCameraRollScanStarted() {
    if (_cameraRollScanStarted) return;
    _cameraRollScanStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scanCameraRoll());
  }

  Future<void> _scanCameraRoll() async {
    if (!mounted) return;
    final state = await CameraRollMatcher.permissionState();
    if (!mounted) return;
    if (!state.hasAccess) {
      setState(
        () =>
            _cameraRollScan = const _CameraRollScan(_CameraRollStatus.noAccess),
      );
      return;
    }
    final matches = await CameraRollMatcher.find(
      startedAt: widget.summary.startedAt,
      endedAt: widget.summary.endedAt,
    );
    if (!mounted) return;
    setState(() {
      _cameraRollScan = matches.isEmpty
          ? const _CameraRollScan(_CameraRollStatus.noMatches)
          : _CameraRollScan(_CameraRollStatus.matchesFound, matches);
    });
  }

  /// The "Find photos from this trip" link's tap target - the only place
  /// this feature actually asks the OS for photo-library access.
  Future<void> _requestCameraRollAccess() async {
    final state = await CameraRollMatcher.requestPermission();
    if (!mounted) return;
    if (!state.hasAccess) {
      showAppToast(
        context,
        variant: AppToastVariant.error,
        title: 'Photo access is off',
        message: 'Turn it on in Settings to find trip photos automatically.',
        actionLabel: 'Settings',
        onAction: CameraRollMatcher.openSettings,
      );
      return;
    }
    await _scanCameraRoll();
  }

  Future<void> _loadMediaLimit() async {
    final limit = await ref.read(journeyMediaLimitProvider.future);
    if (mounted) setState(() => _mediaLimit = limit);
  }

  int get _slotsLeft => photosThatFit(
    _mediaLimit,
    used: widget.media.length,
    wanted: 1 << 30,
  );

  /// True (after telling the user) when the Trip can't take another photo.
  bool _tripIsFull() {
    final limit = _mediaLimit;
    if (limit == null || !limit.isFull(widget.media.length)) return false;
    showAppToast(
      context,
      variant: AppToastVariant.warning,
      title: 'Trip media is full',
      message: limit.fullMessage,
    );
    return true;
  }

  Future<void> _addPhotosManually() async {
    if (_addingPhotos || _tripIsFull()) return;
    setState(() => _addingPhotos = true);
    try {
      await addJourneyPhotosToTrip(
        context,
        ref,
        widget.summary,
        maxPhotos: _mediaLimit == null ? null : _slotsLeft,
      );
    } finally {
      if (mounted) setState(() => _addingPhotos = false);
    }
  }

  Future<void> _addAllMatches() async {
    if (_addingPhotos || _tripIsFull()) return;
    setState(() => _addingPhotos = true);
    try {
      final matches = _cameraRollScan.matches;
      // The card's own label already tells the user when this is a
      // partial add ("Add 24 of 34") - the rest stay reachable via
      // "Choose" rather than silently never making it onto the Trip.
      final cap = _matchAddCap;
      final capped = matches.length > cap ? matches.sublist(0, cap) : matches;
      await addCameraRollMatchesToTrip(context, ref, widget.summary, capped);
    } finally {
      if (mounted) setState(() => _addingPhotos = false);
    }
  }

  /// How many camera-roll matches one tap may add: the one-tap cap, or the
  /// Trip's free slots when fewer.
  int get _matchAddCap => _mediaLimit == null
      ? CameraRollMatcher.maxAutoAdd
      : _slotsLeft.clamp(0, CameraRollMatcher.maxAutoAdd);

  Future<void> _chooseMatches() async {
    if (_tripIsFull()) return;
    var chosen = await showCameraRollMatchPicker(
      context,
      _cameraRollScan.matches,
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;
    if (_mediaLimit != null && chosen.length > _slotsLeft) {
      chosen = chosen.sublist(0, _slotsLeft);
      showAppToast(
        context,
        variant: AppToastVariant.warning,
        title: 'Only room for ${chosen.length} more',
        message: 'The rest were left out.',
      );
    }
    setState(() => _addingPhotos = true);
    try {
      await addCameraRollMatchesToTrip(context, ref, widget.summary, chosen);
    } finally {
      if (mounted) setState(() => _addingPhotos = false);
    }
  }

  /// Handed to [JourneyTimelineMomentRow.onDeletePhoto] - its own
  /// [BuildContext] (the full-screen photo viewer's, not this screen's)
  /// is what the confirm sheet and toast anchor to.
  Future<bool> _removePhoto(BuildContext context, JourneyMediaItem photo) =>
      removeJourneyMedia(context, ref, widget.summary.id, photo);

  /// Opens the Trip media bottom sheet (Journey Replay 3a). Rebuilds on
  /// [_sheetTick] so photos, the camera-roll scan and the add spinner
  /// stay live while it is open.
  Future<void> _openTripMedia() {
    unawaited(_loadMediaLimit());
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ListenableBuilder(
        listenable: _sheetTick,
        builder: (sheetContext, _) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(sheetContext).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                _TripMediaSheetBody(
                  media: widget.media,
                  mediaLoading: widget.mediaLoading,
                  addingPhotos: _addingPhotos,
                  limit: _mediaLimit,
                  onAddPhotos: _addPhotosManually,
                  onFindPhotos: _requestCameraRollAccess,
                  onDeletePhoto: _removePhoto,
                ),
                if (!_matchesDismissed &&
                    _cameraRollScan.status == _CameraRollStatus.matchesFound)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _CameraRollMatchCard(
                      matches: _cameraRollScan.matches,
                      busy: _addingPhotos,
                      addLimit: _matchAddCap,
                      onAddAll: _addAllMatches,
                      onChoose: _chooseMatches,
                      onDismiss: () => setState(() => _matchesDismissed = true),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
