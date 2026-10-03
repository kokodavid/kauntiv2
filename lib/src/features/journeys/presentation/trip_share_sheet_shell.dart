part of 'trip_share_sheet.dart';

/// The two share shapes offered from the sheet - Feed (4:5) and Stories
/// (9:16), per the Claude-Design "Trip Share Card" reference. The history
/// card's own thumbnail shape isn't offered here; it's generated and
/// cached separately (see [TripShareCardThumbnail]).
enum _ShareShape {
  feed(
    width: 360,
    height: 450,
    label: 'Feed',
    ratioLabel: '4:5',
    cacheSuffix: '_feed',
  ),
  story(
    width: 360,
    height: 640,
    label: 'Story',
    ratioLabel: '9:16',
    cacheSuffix: '_story',
  );

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
  unawaited(
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
    ),
  );
}

class _TripShareSheet extends ConsumerStatefulWidget {
  const _TripShareSheet({required this.journeyId, required this.route});

  final String journeyId;
  final JourneyRoute route;

  @override
  ConsumerState<_TripShareSheet> createState() => _TripShareSheetState();
}
