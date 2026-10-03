part of 'trip_share_sheet.dart';

mixin _TripShareSheetActions on _TripShareSheetStateBase {
  @override
  void initState() {
    super.initState();
    unawaited(_checkInstagramAvailability());
  }

  Future<void> _checkInstagramAvailability() async {
    final available = await AppInstagramStories.isAvailable();
    if (mounted) setState(() => _instagramAvailable = available);
  }

  /// The synced photo the strip should show as highlighted - the user's
  /// explicit tap, or the Trip's resolved [defaultCover] when they
  /// haven't chosen one yet. Null (not [defaultCover]) once a local
  /// phone photo is active - no synced thumbnail is "selected" then.
  JourneyMediaItem? _resolveSelected(
    List<JourneyMediaItem> media,
    JourneyMediaItem? defaultCover,
  ) {
    if (_localPhoto != null) return null;
    final id = _selectedMediaId;
    if (id == null) return defaultCover;
    for (final item in media) {
      if (item.id == id) return item;
    }
    return defaultCover;
  }

  ImageProvider? _effectivePhoto(JourneyMediaItem? selected) {
    final local = _localPhoto;
    if (local != null) return MemoryImage(local);
    return selected == null ? null : NetworkImage(selected.url);
  }

  /// Picks [item] immediately for the preview, then persists it as the
  /// Trip's cover photo in the background - same write
  /// ([SupabaseJourneyRepository.setCoverPhoto]) the old "Change photo"
  /// picker made, just fired straight from the tap instead of needing
  /// its own confirm step. A failure here doesn't undo the local
  /// selection - this sheet's own preview is already showing the right
  /// photo either way, only the history card's thumbnail would miss the
  /// update, so it's logged rather than surfaced as an error.
  Future<void> _selectMedia(
    JourneySummary summary,
    JourneyMediaItem item,
  ) async {
    setState(() {
      _selectedMediaId = item.id;
      _localPhoto = null;
    });
    final userId = ref.read(currentUserIdProvider)();
    final cloud = ref.read(supabaseJourneyRepositoryProvider);
    if (userId == null || cloud == null) return;
    try {
      await updateJourneyCoverPhoto(
        cloud,
        userId: userId,
        id: widget.journeyId,
        mediaId: item.id,
      );
      await ref
          .read(tripShareCardCacheAccessProvider)
          .invalidate(widget.journeyId);
      ref.invalidate(journeyDetailProvider(widget.journeyId));
    } on Object catch (error, stackTrace) {
      _TripShareSheetStateBase._logger.warning(
        'Setting cover photo from the share sheet failed for ${widget.journeyId}',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _pickFromPhone() async {
    final AppPickedImage? picked;
    try {
      picked = await AppMediaPicker.pickImage(
        source: AppImageSource.gallery,
        maxWidth: 2048,
        imageQuality: 85,
      );
    } on Object {
      if (!mounted) return;
      showAppToast(
        context,
        variant: AppToastVariant.error,
        title: "Couldn't open your photos",
      );
      return;
    }
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _localPhoto = bytes;
      _selectedMediaId = null;
    });
  }

  /// The Share button's current on-screen rect, for
  /// [AppShare.image]'s `origin`. Null only if the button hasn't been
  /// laid out yet (shouldn't happen - this is read right after the user
  /// taps it), in which case [AppShare.image] falls back to the full
  /// screen, which iOS also accepts.
  Rect? _shareOrigin() {
    final box = _shareButtonKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _share(JourneySummary summary, ImageProvider? photo) async {
    setState(() => _sharing = true);
    try {
      final bytes = await _renderBytes(summary, photo);
      if (!mounted) return;
      final navigator = Navigator.of(context);
      await AppShare.image(
        bytes,
        fileName: 'kaunti47_${summary.id}${_shape.cacheSuffix}.png',
        text: summary.title,
        origin: _shareOrigin(),
      );
      if (navigator.canPop()) navigator.pop();
    } on Object catch (error, stackTrace) {
      _TripShareSheetStateBase._logger.warning(
        'Trip share image generation failed for ${widget.journeyId}',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't prepare that image.")),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// Opens Instagram straight into its Stories composer with the
  /// rendered card pre-loaded, bypassing the system share sheet
  /// entirely (see [AppInstagramStories]). [_instagramAvailable] already
  /// confirms Instagram can accept the handoff before this button even
  /// shows, so a false return here means Instagram declined at the last
  /// moment (e.g. it was uninstalled mid-session) rather than "not
  /// installed" - either way, there's nothing more specific to tell the
  /// user than that it didn't open.
  Future<void> _shareToInstagram(
    JourneySummary summary,
    ImageProvider? photo,
  ) async {
    setState(() => _sharingInstagram = true);
    try {
      final bytes = await _renderBytes(summary, photo);
      if (!mounted) return;
      final opened = await AppInstagramStories.share(
        bytes,
        // Matches the page background the card itself sits on, so any
        // sliver Instagram fills in around the image (it doesn't force
        // a crop) blends in rather than showing as a stray bar.
        backgroundTopColor: '#F5F5F5',
        backgroundBottomColor: '#F5F5F5',
      );
      if (!opened) throw StateError('Instagram declined the share.');
    } on Object catch (error, stackTrace) {
      _TripShareSheetStateBase._logger.warning(
        'Instagram Stories share failed for ${widget.journeyId}',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't open Instagram.")));
    } finally {
      if (mounted) setState(() => _sharingInstagram = false);
    }
  }

  /// Saves the same rendered image straight to Photos, without opening
  /// the OS share sheet - the left-hand button next to Share
  /// (Claude-Design "Share Sheet 3a" reference: "Save (left) writes the
  /// image to Photos without the share sheet").
  Future<void> _saveToPhotos(
    JourneySummary summary,
    ImageProvider? photo,
  ) async {
    setState(() => _saving = true);
    try {
      final bytes = await _renderBytes(summary, photo);
      if (!mounted) return;
      // Throws on failure (denied permission, disk error) rather than
      // returning null - the catch block below is what actually
      // handles that, not a null check here.
      await PhotoManager.editor.saveImage(
        bytes,
        filename:
            'kaunti47_${summary.id}${_shape.cacheSuffix}_'
            '${DateTime.now().millisecondsSinceEpoch}.png',
      );
      if (!mounted) return;
      showAppToast(
        context,
        variant: AppToastVariant.success,
        title: 'Saved to Photos',
      );
    } on Object catch (error, stackTrace) {
      _TripShareSheetStateBase._logger.warning(
        'Trip share image save-to-Photos failed for ${widget.journeyId}',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      showAppToast(
        context,
        variant: AppToastVariant.error,
        title: "Couldn't save it",
        message: 'Check that Kaunti47 can add photos in Settings.',
        actionLabel: 'Settings',
        onAction: PhotoManager.openSetting,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Renders the current shape/photo choice to PNG bytes - shared by
  /// [_share] and [_saveToPhotos], which differ only in what they do
  /// with the result.
  Future<Uint8List> _renderBytes(
    JourneySummary summary,
    ImageProvider? photo,
  ) async {
    if (photo != null) {
      await precacheImage(photo, context);
    }
    if (!mounted) throw StateError('Unmounted mid-render');

    final routePoints = photo == null
        ? TripShareCard.normalizeRoute(
            ref
                .read(tripShareCardCacheAccessProvider)
                .mainRoutePoints(widget.route),
          )
        : const <Offset>[];

    return captureTripShareCard(
      context: context,
      card: TripShareCard(
        variant: TripShareCardVariant.share,
        width: _shape.width,
        height: _shape.height,
        title: summary.title,
        startedAt: summary.startedAt,
        endedAt: summary.endedAt,
        transportMode: summary.transportMode,
        distanceMeters: summary.distanceMeters,
        topSpeedMps: summary.topSpeedMps,
        averageSpeedMps: summary.averageSpeedMps,
        highestElevationMeters: summary.highestElevationMeters,
        countyNames: summary.countyNames,
        photo: photo,
        routePoints: routePoints,
      ),
      pixelRatio: 3,
    );
  }
}
