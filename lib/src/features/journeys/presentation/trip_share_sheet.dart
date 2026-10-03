import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/services/app_instagram_stories.dart';
import '../../../core/services/app_share.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_floating_toast.dart';
import '../../../design/app_text_styles.dart';
import '../../../services/app_logger.dart';
import '../../../widgets/app_glyph_icon.dart';
import '../../auth/application/auth_providers.dart';
import '../application/journey_cloud_providers.dart';
import '../application/journey_views.dart';
import '../data/trip_share_card_cache.dart';
import '../domain/journey_media_capture.dart';
import '../domain/journey_route.dart';
import '../domain/journey_summary.dart';
import 'trip_share_card.dart';
import 'trip_share_card_renderer.dart';

/// The two share shapes offered from the sheet - Feed (4:5) and Stories
/// (9:16), per the Claude-Design "Trip Share Card" reference. The history
/// card's own thumbnail shape isn't offered here; it's generated and
/// cached separately (see [TripShareCardThumbnail]).
enum _ShareShape {
  feed(width: 360, height: 450, label: 'Feed', ratioLabel: '4:5', cacheSuffix: '_feed'),
  story(width: 360, height: 640, label: 'Story', ratioLabel: '9:16', cacheSuffix: '_story');

  const _ShareShape({
    required this.width,
    required this.height,
    required this.label,
    required this.ratioLabel,
    required this.cacheSuffix,
  });

  final double width;
  final double height;
  final String label;
  final String ratioLabel;
  final String cacheSuffix;
}

/// A Feed/Story preview sheet for sharing a Trip (Claude-Design "Share
/// Sheet 3a" reference): a fixed-height preview (so the photo strip and
/// Share button always have room below it regardless of shape), the
/// Trip's own synced photos as a tappable strip - "From phone" at the
/// end opens the system picker for anything else - and Save/Share
/// actions side by side. Opened from the Replay screen's share button.
void showTripShareSheet(
  BuildContext context, {
  required JourneySummary summary,
  required JourneyRoute route,
}) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: AppColors.sheetBarrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) =>
        _TripShareSheet(journeyId: summary.id, route: route),
  );
}

class _TripShareSheet extends ConsumerStatefulWidget {
  const _TripShareSheet({required this.journeyId, required this.route});

  final String journeyId;
  final JourneyRoute route;

  @override
  ConsumerState<_TripShareSheet> createState() => _TripShareSheetState();
}

class _TripShareSheetState extends ConsumerState<_TripShareSheet> {
  static const _logger = AppLogger.journeys();

  /// Fixed regardless of [_shape] - Feed's preview is 296x370 (its own
  /// 4:5 ratio at this height), Story's is narrower at the same height
  /// (9:16 is taller/narrower, not shorter) - rather than the old
  /// full-width preview, which left no room below it for the photo
  /// strip and Share button on the taller Story shape.
  static const _previewHeight = 370.0;

  _ShareShape _shape = _ShareShape.feed;

  /// The Trip's own synced photo the user tapped in the strip, if any -
  /// cleared by picking one from the phone instead. Null with
  /// [_localPhoto] also null means "no explicit choice yet", which
  /// falls back to the Trip's resolved cover photo (its chosen cover,
  /// or earliest synced photo).
  String? _selectedMediaId;

  /// Picked via "From phone"; overrides [_selectedMediaId] when set -
  /// only one of the two is ever the active choice.
  XFile? _localPhoto;

  var _sharing = false;
  var _saving = false;
  var _sharingInstagram = false;

  /// Whether to show the Instagram Stories button at all - only once
  /// we've confirmed Instagram is actually installed and the device can
  /// open its Stories scheme ([AppInstagramStories.isAvailable]); a
  /// button that opens nothing is worse than no button.
  var _instagramAvailable = false;

  @override
  void initState() {
    super.initState();
    unawaited(_checkInstagramAvailability());
  }

  Future<void> _checkInstagramAvailability() async {
    final available = await AppInstagramStories.isAvailable();
    if (mounted) setState(() => _instagramAvailable = available);
  }

  /// Anchors the iOS share popover to the Share button itself. iOS
  /// requires `sharePositionOrigin` to be a real, non-zero rect in the
  /// presenting view's coordinate space - passing nothing (as this used
  /// to) throws a PlatformException ("sharePositionOrigin: argument must
  /// be set") rather than falling back to some default position, which
  /// is what was behind every real-device Share tap failing with
  /// "Couldn't prepare that image." Android and iPhone both ignore this
  /// rect outside of an iPad popover, so it's harmless there.
  final _shareButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(journeyDetailProvider(widget.journeyId)).value?.summary;
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

    final defaultCover = TripShareCardCache.resolveCoverPhoto(summary, media);
    final selected = _resolveSelected(media, defaultCover);
    final photo = _effectivePhoto(selected);
    final previewWidth = _previewHeight / _shape.height * _shape.width;

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
                  Expanded(
                    child: Text('Share trip', style: AppTextStyles.confirmSheetTitle),
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
                  height: _previewHeight,
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
                                  TripShareCardCache.mainRoutePoints(
                                    widget.route,
                                  ),
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
                  Text(
                    'Photos from this trip',
                    style: _Styles.stripHeading,
                  ),
                  Text(
                    media.length == 1 ? '1 in timeline' : '${media.length} in timeline',
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
                                child: CircularProgressIndicator(strokeWidth: 2),
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
    if (local != null) return FileImage(File(local.path));
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
  Future<void> _selectMedia(JourneySummary summary, JourneyMediaItem item) async {
    setState(() {
      _selectedMediaId = item.id;
      _localPhoto = null;
    });
    final userId = ref.read(currentUserIdProvider)();
    final cloud = ref.read(supabaseJourneyRepositoryProvider);
    if (userId == null || cloud == null) return;
    try {
      await cloud.setCoverPhoto(userId: userId, id: widget.journeyId, mediaId: item.id);
      await TripShareCardCache.invalidate(widget.journeyId);
      ref.invalidate(journeyDetailProvider(widget.journeyId));
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Setting cover photo from the share sheet failed for ${widget.journeyId}',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _pickFromPhone() async {
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
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
    setState(() {
      _localPhoto = picked;
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
      _logger.warning(
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
      _logger.warning(
        'Instagram Stories share failed for ${widget.journeyId}',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open Instagram.")),
      );
    } finally {
      if (mounted) setState(() => _sharingInstagram = false);
    }
  }

  /// Saves the same rendered image straight to Photos, without opening
  /// the OS share sheet - the left-hand button next to Share
  /// (Claude-Design "Share Sheet 3a" reference: "Save (left) writes the
  /// image to Photos without the share sheet").
  Future<void> _saveToPhotos(JourneySummary summary, ImageProvider? photo) async {
    setState(() => _saving = true);
    try {
      final bytes = await _renderBytes(summary, photo);
      if (!mounted) return;
      // Throws on failure (denied permission, disk error) rather than
      // returning null - the catch block below is what actually
      // handles that, not a null check here.
      await PhotoManager.editor.saveImage(
        bytes,
        filename: 'kaunti47_${summary.id}${_shape.cacheSuffix}_'
            '${DateTime.now().millisecondsSinceEpoch}.png',
      );
      if (!mounted) return;
      showAppToast(
        context,
        variant: AppToastVariant.success,
        title: 'Saved to Photos',
      );
    } on Object catch (error, stackTrace) {
      _logger.warning(
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
            TripShareCardCache.mainRoutePoints(widget.route),
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

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.lockedFill,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, size: 16, color: AppColors.mutedForeground),
      ),
    );
  }
}

class _ShapeToggle extends StatelessWidget {
  const _ShapeToggle({required this.shape, required this.onChanged});

  final _ShareShape shape;
  final ValueChanged<_ShareShape> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.lockedFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final option in _ShareShape.values)
            Expanded(
              child: _ShapeChip(
                shape: option,
                selected: option == shape,
                onTap: () => onChanged(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShapeChip extends StatelessWidget {
  const _ShapeChip({
    required this.shape,
    required this.selected,
    required this.onTap,
  });

  final _ShareShape shape;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              shape.label,
              style: _Styles.shapeLabel.copyWith(
                color: selected ? AppColors.buttonForeground : AppColors.mutedForeground,
              ),
            ),
            const SizedBox(width: 6),
            Text(shape.ratioLabel, style: _Styles.shapeRatio),
          ],
        ),
      ),
    );
  }
}

/// The Trip's own synced photos, oldest first, each tappable to pick it
/// for the preview/share/save - plus a trailing "From phone" tile that
/// opens the system photo picker. Scrolls horizontally rather than
/// wrapping, same as the Claude-Design "Share Sheet 3a" reference.
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.media,
    required this.selectedId,
    required this.onSelect,
    required this.onPickFromPhone,
  });

  final List<JourneyMediaItem> media;
  final String? selectedId;
  final ValueChanged<JourneyMediaItem> onSelect;
  final VoidCallback onPickFromPhone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // +6 over the thumb column's own ~78px (60 image + 4 gap + the
      // time label) - headroom for the selected thumb's glow ring and
      // checkmark badge below, which paint above the 60x60 image via a
      // spreading BoxShadow and a Positioned(top: -5) badge. Without it,
      // ListView's default Clip.hardEdge (flush with this box's top
      // edge) clips the top of that ring/badge off a selected thumb.
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: 6),
        children: [
          for (final item in media) ...[
            _PhotoThumb(
              item: item,
              selected: item.id == selectedId,
              onTap: () => onSelect(item),
            ),
            const SizedBox(width: 8),
          ],
          if (media.isNotEmpty)
            Container(
              width: 1,
              height: 44,
              margin: const EdgeInsets.only(top: 8, right: 8),
              color: AppColors.cardBorder,
            ),
          _FromPhoneTile(onTap: onPickFromPhone),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final JourneyMediaItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(item.capturedAt.toLocal()).format(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? const [
                      BoxShadow(color: Colors.white, spreadRadius: 2),
                      BoxShadow(color: AppColors.accent, spreadRadius: 4),
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.url,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    cacheWidth: 120,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(color: AppColors.lockedFill),
                  ),
                ),
                if (selected)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: selected ? _Styles.thumbTimeSelected : _Styles.thumbTime,
          ),
        ],
      ),
    );
  }
}

class _FromPhoneTile extends StatelessWidget {
  const _FromPhoneTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.lockedFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              size: 22,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text('From phone', style: _Styles.thumbTimeSelected),
        ],
      ),
    );
  }
}

abstract final class _Styles {
  static const stripHeading = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.mutedForeground,
  );
  static const stripCount = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.toastSubtitle,
  );
  static const shapeLabel = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
  static const shapeRatio = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.toastSubtitle,
  );
  static const thumbTime = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedForeground,
  );
  static const thumbTimeSelected = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    color: AppColors.accent,
  );
}
