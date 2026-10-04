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
        NetworkImage(photo.url),
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

  Future<void> _addPhotosManually() async {
    if (_addingPhotos) return;
    setState(() => _addingPhotos = true);
    try {
      await addJourneyPhotosToTrip(context, ref, widget.summary);
    } finally {
      if (mounted) setState(() => _addingPhotos = false);
    }
  }

  Future<void> _addAllMatches() async {
    if (_addingPhotos) return;
    setState(() => _addingPhotos = true);
    try {
      final matches = _cameraRollScan.matches;
      // The card's own label already tells the user when this is a
      // partial add ("Add 24 of 34") - the rest stay reachable via
      // "Choose" rather than silently never making it onto the Trip.
      final capped = matches.length > CameraRollMatcher.maxAutoAdd
          ? matches.sublist(0, CameraRollMatcher.maxAutoAdd)
          : matches;
      await addCameraRollMatchesToTrip(context, ref, widget.summary, capped);
    } finally {
      if (mounted) setState(() => _addingPhotos = false);
    }
  }

  Future<void> _chooseMatches() async {
    final chosen = await showCameraRollMatchPicker(
      context,
      _cameraRollScan.matches,
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;
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
}
