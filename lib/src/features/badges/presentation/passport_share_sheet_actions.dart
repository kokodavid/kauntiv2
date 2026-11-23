part of 'passport_share_sheet.dart';

mixin _PassportShareSheetActions on _PassportShareSheetStateBase {
  @override
  void initState() {
    super.initState();
    unawaited(_checkInstagram());
  }

  Future<void> _checkInstagram() async {
    final available = await AppInstagramStories.isAvailable();
    if (mounted) setState(() => _instagramAvailable = available);
  }

  /// The Photo style needs a photo: picking one switches to it.
  Future<void> _pickPhoto() async {
    final AppPickedImage? picked;
    try {
      picked = await AppMediaPicker.pickImage(
        source: AppImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
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
      _photo = MemoryImage(bytes);
      _style = PassportShareStyle.photo;
    });
  }

  void _pickStyle(PassportShareStyle style) {
    if (style == PassportShareStyle.photo && _photo == null) {
      unawaited(_pickPhoto());
      return;
    }
    setState(() => _style = style);
  }

  Rect? _shareOrigin() {
    final box = _shareButtonKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  String get _fileStem => 'kaunti47_passport_${_style.name}';

  /// Renders the current choice at 3x. Every image on the card is
  /// decoded first, since the off-screen capture doesn't wait for them.
  Future<Uint8List> _render() async {
    final images = <ImageProvider>[
      if (_style == PassportShareStyle.passport && _showArt)
        const AssetImage(PassportTravellerCard.artAsset),
      if (_style == PassportShareStyle.passport)
        if (widget.book.latestStamp case final county?)
          if (PassportStampArt.has(county))
            AssetImage(PassportStampArt.assetFor(county)),
      if (_style == PassportShareStyle.photo) ?_photo,
    ];
    for (final image in images) {
      await precacheImage(image, context);
      if (!mounted) throw StateError('Unmounted mid-render');
    }
    return captureShareCard(context: context, card: _card(), pixelRatio: 3);
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final bytes = await _render();
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final book = widget.book;
      await AppShare.image(
        bytes,
        fileName: '$_fileStem.png',
        text:
            'My Kenya Passport on Kaunti47: ${book.claimedCount} of '
            '${book.total} counties explored.',
        origin: _shareOrigin(),
      );
      if (navigator.canPop()) navigator.pop();
    } on Object catch (error, stackTrace) {
      _PassportShareSheetStateBase._logger.warning(
        'Passport share image failed.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      showAppToast(
        context,
        variant: AppToastVariant.error,
        title: "Couldn't prepare that image",
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _shareToInstagram() async {
    setState(() => _sharingInstagram = true);
    try {
      final bytes = await _render();
      if (!mounted) return;
      final paper = _style == PassportShareStyle.passport;
      final opened = await AppInstagramStories.share(
        bytes,
        backgroundTopColor: paper ? '#EAF3FC' : '#000000',
        backgroundBottomColor: paper ? '#F8F1EA' : '#000000',
      );
      if (!opened) throw StateError('Instagram declined the share.');
    } on Object catch (error, stackTrace) {
      _PassportShareSheetStateBase._logger.warning(
        'Passport Instagram Stories share failed.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      showAppToast(
        context,
        variant: AppToastVariant.error,
        title: "Couldn't open Instagram",
      );
    } finally {
      if (mounted) setState(() => _sharingInstagram = false);
    }
  }

  Future<void> _saveToPhotos() async {
    setState(() => _saving = true);
    try {
      final bytes = await _render();
      if (!mounted) return;
      await PhotoManager.editor.saveImage(
        bytes,
        filename: '${_fileStem}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      if (!mounted) return;
      showAppToast(
        context,
        variant: AppToastVariant.success,
        title: 'Saved to Photos',
      );
    } on Object catch (error, stackTrace) {
      _PassportShareSheetStateBase._logger.warning(
        'Passport share save-to-Photos failed.',
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
}
