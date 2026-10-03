import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/counties/county_boundary_resolver.dart';
import '../../../core/design/app_type_scale.dart';
import '../../../core/services/camera_roll_matcher.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/journey_key_moments.dart';
import '../domain/journey_county_moment_facts.dart';
import '../domain/journey_media_capture.dart';
import '../domain/journey_moments.dart';
import '../domain/journey_point.dart';
import '../domain/journey_summary.dart';
import 'journey_camera_roll_sheet.dart';
import 'journey_moment_row.dart';
import 'journey_trip_media_actions.dart';

/// The scrollable story below the map: the Trip's date and title, then
/// every key moment in order. Replay drives which one is "current"; the
/// timeline brings it into view instead of popping a separate card.
class JourneyReplayTimeline extends ConsumerStatefulWidget {
  const JourneyReplayTimeline({
    super.key,
    required this.summary,
    required this.points,
    required this.moments,
    required this.currentMoments,
    required this.onJumpTo,
    this.onOpenCounty,
    this.momentsLoading = false,
    this.topPadding = 0,
    this.bottomPadding = 0,
  });

  final JourneySummary summary;
  final List<JourneyPoint> points;
  final List<JourneyMoment> moments;

  /// True while `journeyMomentsProvider` is still resolving its first
  /// value - shows a spinner instead of the empty-timeline card, so a
  /// Trip that simply hasn't finished computing its moments isn't
  /// briefly mistaken for one with none.
  final bool momentsLoading;

  /// The moment(s) replay is currently paused at, if any ("lit up").
  final List<JourneyMoment> currentMoments;

  /// Jumps the replay to a moment's point in the route.
  final ValueChanged<int> onJumpTo;
  final ValueChanged<int>? onOpenCounty;

  final double topPadding;
  final double bottomPadding;

  @override
  ConsumerState<JourneyReplayTimeline> createState() =>
      _JourneyReplayTimelineState();
}

/// How the camera-roll auto-match (Claude-Design "2b" reference) stands
/// for this Trip. [idle] only until the first post-frame check runs;
/// [noAccess] covers both "never asked" and "denied" - the empty-timeline
/// card treats them the same (offer to ask), and [CameraRollMatcher]
/// itself is what actually distinguishes them when asked to request.
enum _CameraRollStatus { idle, noAccess, noMatches, matchesFound }

class _CameraRollScan {
  const _CameraRollScan(this.status, [this.matches = const []]);

  final _CameraRollStatus status;
  final List<CameraRollMatch> matches;
}

class _JourneyReplayTimelineState extends ConsumerState<JourneyReplayTimeline> {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _precachePhotos();
    });
  }

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
      await precacheImage(NetworkImage(photo.url), context);
    } on Object {
      // A failed precache just means the row's own Image.network fetches
      // it normally when it scrolls into view (and shows its own
      // errorBuilder if that fails too) - nothing to surface here.
    }
  }

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

  GlobalKey _keyFor(JourneyMoment moment) =>
      _rowKeys.putIfAbsent(_keyTuple(moment), GlobalKey.new);

  @override
  void didUpdateWidget(JourneyReplayTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
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
      await addCameraRollMatchesToTrip(
        context,
        ref,
        widget.summary,
        _cameraRollScan.matches,
      );
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
    // Whether to offer the camera-roll suggestion at all: a Trip can have
    // other moments (stops, crossings...) and still have zero photos, and
    // that's just as much a "no photos yet" Trip as a fully empty one.
    final hasPhotos = widget.moments.any((moment) => moment.isPhoto);
    final showInlineSuggestion = !showEmptyBody && !hasPhotos;
    if (!hasPhotos && !widget.momentsLoading) {
      _ensureCameraRollScanStarted();
    }
    final momentCount = showEmptyBody ? 0 : widget.moments.length;
    final hasFooter = !showEmptyBody && showInlineSuggestion;
    // Index 0 is always the header (date/title/empty-body card); then one
    // item per moment; then an optional footer. A single flat,
    // lazily-built ListView rather than a CustomScrollView of grouped
    // slivers (SliverMainAxisGroup) - that combination, with this list's
    // GlobalKey-keyed rows, was tripping a Flutter framework semantics
    // assertion ('!semantics.parentDataDirty') while the screen's
    // ticker-driven map/scrubber rebuilt nearby. ListView.builder is the
    // standard, well-tested virtualization path and keeps the same lazy,
    // don't-build-offscreen-photos behavior.
    final itemCount = 1 + momentCount + (hasFooter ? 1 : 0);
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
                Text(
                  _dateRange(widget.summary.startedAt, widget.summary.endedAt),
                  style: AppTypeScale.meta.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.summary.title,
                  style: AppTypeScale.sectionTitle.copyWith(fontSize: 22),
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
              ),
            );
          }
          // The only slot left once the header and every moment are
          // accounted for is the footer - only reachable when hasFooter
          // made itemCount include it.
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _InlineCameraRollSuggestion(
              cameraRoll: _cameraRollScan,
              addingPhotos: _addingPhotos,
              onAddPhotos: _addPhotosManually,
              onFindPhotos: _requestCameraRollAccess,
              onAddAllMatches: _addAllMatches,
              onChooseMatches: _chooseMatches,
            ),
          );
        },
      ),
    );
  }

  DateTime? _timeAt(int index) => index >= 0 && index < widget.points.length
      ? widget.points[index].recordedAt
      : null;
}

/// What the timeline shows in place of a moment list when a Trip has
/// none: start and end are always known from GPS, so they're always
/// shown (Claude-Design "2a" reference), with a card in the gap between
/// them offering to fill it in - either the camera-roll auto-match
/// (Claude-Design "2b") once photos are found, or the plain "Add photos"
/// / "Add note" pair as the fallback.
class _EmptyTimelineBody extends StatelessWidget {
  const _EmptyTimelineBody({
    required this.loading,
    required this.startedAt,
    required this.endedAt,
    required this.startCounty,
    required this.endCounty,
    required this.addingPhotos,
    required this.onAddPhotosManually,
    required this.cameraRoll,
    required this.onFindPhotos,
    required this.onAddAllMatches,
    required this.onChooseMatches,
  });

  final bool loading;
  final DateTime startedAt;
  final DateTime endedAt;
  final String? startCounty;
  final String? endCounty;
  final bool addingPhotos;
  final VoidCallback onAddPhotosManually;
  final _CameraRollScan cameraRoll;
  final VoidCallback onFindPhotos;
  final VoidCallback onAddAllMatches;
  final VoidCallback onChooseMatches;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: AppProgressIndicator(color: AppColors.accent, radius: 10),
        ),
      );
    }
    final startAt = TimeOfDay.fromDateTime(startedAt.toLocal()).format(context);
    final endAt = TimeOfDay.fromDateTime(endedAt.toLocal()).format(context);
    final titleStyle = AppTypeScale.itemTitle.copyWith(
      fontWeight: FontWeight.w600,
    );
    final card = cameraRoll.status == _CameraRollStatus.matchesFound
        ? _CameraRollMatchCard(
            matches: cameraRoll.matches,
            busy: addingPhotos,
            onAddAll: onAddAllMatches,
            onChoose: onChooseMatches,
          )
        : _AddMomentsCard(
            title: 'No moments on this trip',
            message: 'The replay pauses at each photo or note.',
            onAddPhotos: onAddPhotosManually,
            addingPhotos: addingPhotos,
            showFindPhotosLink: cameraRoll.status == _CameraRollStatus.noAccess,
            onFindPhotos: onFindPhotos,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.accent,
                    child: Icon(
                      Icons.trip_origin,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.cardBorder,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        startAt,
                        style: AppTypeScale.meta.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        startCounty == null
                            ? 'Trip started'
                            : 'Started in $startCounty',
                        style: titleStyle,
                      ),
                      const SizedBox(height: 8),
                      card,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.buttonForeground,
              child: Icon(Icons.flag, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      endAt,
                      style: AppTypeScale.meta.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      endCounty == null
                          ? 'Trip ended'
                          : 'Arrived in $endCounty',
                      style: titleStyle,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The "fill the gap" card: a headline/message pair plus an "Add photos"
/// / "Add note" pill pair (Claude-Design "2a" reference), with an
/// optional link to opt into the camera-roll auto-match - shown only
/// while that access hasn't been granted yet, so it's an invitation, not
/// a standing nag once the answer is already known. [title]/[message] and
/// [showAddNote] let this double as both the fully-empty-timeline card
/// and the lighter inline "no photos yet" suggestion (see
/// [_InlineCameraRollSuggestion]) without duplicating the layout.
class _AddMomentsCard extends StatelessWidget {
  const _AddMomentsCard({
    required this.title,
    required this.message,
    required this.onAddPhotos,
    required this.addingPhotos,
    required this.showFindPhotosLink,
    required this.onFindPhotos,
    this.showAddNote = true,
  });

  final String title;
  final String message;
  final VoidCallback onAddPhotos;
  final bool addingPhotos;
  final bool showFindPhotosLink;
  final VoidCallback onFindPhotos;

  /// False for the inline "no photos yet" case, where the Trip may
  /// already have other moments and offering to add a note again isn't
  /// the point of that suggestion.
  final bool showAddNote;

  @override
  Widget build(BuildContext context) {
    final pillLabelStyle = AppTypeScale.action.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.emptyTimelineCardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: pillLabelStyle),
          const SizedBox(height: 2),
          Text(message, style: AppTypeScale.body),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: addingPhotos ? null : onAddPhotos,
                  icon: addingPhotos
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: AppProgressIndicator(
                            color: Colors.white,
                            radius: 7,
                          ),
                        )
                      : const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 16,
                        ),
                  label: Text(addingPhotos ? 'Adding…' : 'Add photos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.accent,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: pillLabelStyle.copyWith(color: Colors.white),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              if (showAddNote) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () => showAppToast(
                      context,
                      variant: AppToastVariant.neutral,
                      title: 'Notes are coming soon',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.buttonForeground,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      textStyle: pillLabelStyle.copyWith(
                        color: AppColors.buttonForeground,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Add note'),
                  ),
                ),
              ],
            ],
          ),
          if (showFindPhotosLink) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onFindPhotos,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 14, color: AppColors.accent),
                  SizedBox(width: 4),
                  Text(
                    'Find photos from this trip',
                    style: AppTypeScale.action,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The lighter-weight sibling of [_EmptyTimelineBody]: for a Trip that
/// already has other moments (stops, crossings, an elevation peak...) but
/// no photos yet, there's a real timeline to keep showing, so this is
/// appended after it rather than replacing it with the full start/end-pin
/// skeleton. Shares the same camera-roll match card and "add photos"
/// fallback card as the fully-empty case, just without the pins.
class _InlineCameraRollSuggestion extends StatelessWidget {
  const _InlineCameraRollSuggestion({
    required this.cameraRoll,
    required this.addingPhotos,
    required this.onAddPhotos,
    required this.onFindPhotos,
    required this.onAddAllMatches,
    required this.onChooseMatches,
  });

  final _CameraRollScan cameraRoll;
  final bool addingPhotos;
  final VoidCallback onAddPhotos;
  final VoidCallback onFindPhotos;
  final VoidCallback onAddAllMatches;
  final VoidCallback onChooseMatches;

  @override
  Widget build(BuildContext context) {
    if (cameraRoll.status == _CameraRollStatus.matchesFound) {
      return _CameraRollMatchCard(
        matches: cameraRoll.matches,
        busy: addingPhotos,
        onAddAll: onAddAllMatches,
        onChoose: onChooseMatches,
      );
    }
    return _AddMomentsCard(
      title: 'No photos on this trip yet',
      message:
          'Add some from your gallery, or let us find them in your '
          'camera roll.',
      onAddPhotos: onAddPhotos,
      addingPhotos: addingPhotos,
      showFindPhotosLink: cameraRoll.status == _CameraRollStatus.noAccess,
      onFindPhotos: onFindPhotos,
      showAddNote: false,
    );
  }
}

/// The camera-roll auto-match card (Claude-Design "2b" reference):
/// "N photos taken on this route", a preview of the first few, and
/// "Add to timeline" (all of them) or "Choose" (a picker to trim the
/// set down).
class _CameraRollMatchCard extends StatelessWidget {
  const _CameraRollMatchCard({
    required this.matches,
    required this.busy,
    required this.onAddAll,
    required this.onChoose,
  });

  final List<CameraRollMatch> matches;
  final bool busy;
  final VoidCallback onAddAll;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final pillLabelStyle = AppTypeScale.action.copyWith(
      fontWeight: FontWeight.w600,
    );
    final preview = matches.take(3).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.emptyTimelineCardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF3FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 17,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      matches.length == 1
                          ? '1 photo taken on this route'
                          : '${matches.length} photos taken on this route',
                      style: pillLabelStyle,
                    ),
                    const Text(
                      'Found in your camera roll',
                      style: AppTypeScale.body,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final match in preview) ...[
                Expanded(child: _ThumbnailTile(match: match)),
                if (match != preview.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: busy ? null : onAddAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.accent,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: AppProgressIndicator(
                              color: Colors.white,
                              radius: 8,
                            ),
                          )
                        : Text(
                            'Add to timeline',
                            style: pillLabelStyle.copyWith(color: Colors.white),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: busy ? null : onChoose,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.buttonForeground,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: pillLabelStyle.copyWith(
                      color: AppColors.buttonForeground,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Choose'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  const _ThumbnailTile({required this.match});

  final CameraRollMatch match;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: FutureBuilder<Uint8List?>(
          future: match.asset.thumbnailDataWithSize(
            const ThumbnailSize.square(200),
          ),
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (bytes == null) {
              return const ColoredBox(color: AppColors.lockedFill);
            }
            return Image.memory(bytes, fit: BoxFit.cover);
          },
        ),
      ),
    );
  }
}

const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const _months = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// "THU 1 OCT · 7:40 – 8:16 AM" (or "...7:40 AM – 1:16 PM" across noon).
String _dateRange(DateTime startedAt, DateTime endedAt) {
  final start = startedAt.toLocal();
  final end = endedAt.toLocal();
  final date =
      '${_weekdays[start.weekday - 1]} ${start.day} ${_months[start.month - 1]}';
  final startPeriod = start.hour < 12 ? 'AM' : 'PM';
  final endPeriod = end.hour < 12 ? 'AM' : 'PM';
  final endTime = '${_hhmm(end)} $endPeriod';
  final range = startPeriod == endPeriod
      ? '${_hhmm(start)} – $endTime'
      : '${_hhmm(start)} $startPeriod – $endTime';
  return '$date · $range';
}

String _hhmm(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
