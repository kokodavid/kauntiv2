part of 'trip_share_sheet.dart';

mixin _TripShareSheetContent
    on _TripShareSheetStateBase, _TripShareSheetActions {
  @override
  Widget build(BuildContext context) {
    final summary = ref
        .watch(journeyDetailProvider(widget.journeyId))
        .value
        ?.summary;
    final media =
        ref.watch(journeyMediaProvider(widget.journeyId)).value ?? const [];

    if (summary == null) {
      // The Trip detail was already loaded to get here (Replay is on
      // screen), so this only shows mid-refresh - a spinner beats
      // flashing the sheet shut.
      return const SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    final cache = ref.read(tripShareCardCacheAccessProvider);
    final defaultCover = cache.resolveCoverPhoto(summary, media);
    final selected = _resolveSelected(media, defaultCover);
    final photo = _effectivePhoto(selected);
    final previewWidth =
        _TripShareSheetStateBase._previewHeight / _shape.height * _shape.width;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.trackInactive,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Share trip',
                      style: AppTextStyles.confirmSheetTitle,
                    ),
                  ),
                  _CloseButton(onTap: () => Navigator.of(context).maybePop()),
                ],
              ),
              const SizedBox(height: 14),
              _ShapeToggle(
                shape: _shape,
                onChanged: (shape) => setState(() => _shape = shape),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: previewWidth,
                  height: _TripShareSheetStateBase._previewHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Transform.scale(
                      scale: previewWidth / _shape.width,
                      alignment: Alignment.topLeft,
                      // OverflowBox, not SizedBox: the outer SizedBox
                      // above is already tight at previewWidth/
                      // _previewHeight (the scaled-down box), and those
                      // tight constraints flow straight through
                      // Transform.scale (it only affects painting, not
                      // layout). A plain SizedBox(_shape.width,
                      // _shape.height) child would get clamped down to
                      // that smaller tight size by
                      // BoxConstraints.constrain, so TripShareCard would
                      // actually lay out - and wrap its stat grid - at
                      // previewWidth (e.g. 296) rather than its real
                      // _shape.width (360), overflowing the stat grid's
                      // fixed-width row by exactly the difference. An
                      // OverflowBox ignores the incoming constraints for
                      // its child, letting the card lay out at its true
                      // full size; Transform.scale then only shrinks the
                      // *painted* result to fit the preview box.
                      child: OverflowBox(
                        minWidth: _shape.width,
                        maxWidth: _shape.width,
                        minHeight: _shape.height,
                        maxHeight: _shape.height,
                        alignment: Alignment.topLeft,
                        child: TripShareCard(
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
                          highestElevationMeters:
                              summary.highestElevationMeters,
                          countyNames: summary.countyNames,
                          photo: photo,
                          routePoints: photo != null
                              ? const []
                              : TripShareCard.normalizeRoute(
                                  cache.mainRoutePoints(widget.route),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'Photos from this trip',
                    style: _Styles.stripHeading,
                  ),
                  Text(
                    media.length == 1
                        ? '1 in timeline'
                        : '${media.length} in timeline',
                    style: _Styles.stripCount,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _PhotoStrip(
                media: media,
                selectedId: _localPhoto == null ? selected?.id : null,
                onSelect: (item) => _selectMedia(summary, item),
                onPickFromPhone: _pickFromPhone,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _saving || _sharing || _sharingInstagram
                          ? null
                          : () => _saveToPhotos(summary, photo),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.lockedFill,
                        foregroundColor: AppColors.buttonForeground,
                        side: BorderSide.none,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const AppGlyphIcon(
                              path: AppGlyphPaths.download,
                              size: 20,
                              color: AppColors.buttonForeground,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_instagramAvailable) ...[
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _saving || _sharing || _sharingInstagram
                            ? null
                            : () => _shareToInstagram(summary, photo),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.lockedFill,
                          foregroundColor: AppColors.buttonForeground,
                          side: BorderSide.none,
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                        ),
                        child: _sharingInstagram
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                size: 20,
                                color: AppColors.buttonForeground,
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
                      key: _shareButtonKey,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _sharing || _saving || _sharingInstagram
                            ? null
                            : () => _share(summary, photo),
                        icon: _sharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const AppGlyphIcon(
                                path: AppGlyphPaths.share,
                                size: 18,
                                color: Colors.white,
                              ),
                        label: Text(
                          _sharing ? 'Preparing…' : 'Share',
                          style: AppTextStyles.confirmSheetButtonLabel,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.accent,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
