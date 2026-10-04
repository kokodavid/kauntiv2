import 'package:photo_manager/photo_manager.dart';

/// One camera-roll photo whose timestamp falls inside a Trip's recorded
/// span, offered for adding to Replay's timeline.
class CameraRollMatch {
  const CameraRollMatch({
    required this.asset,
    required this.capturedAt,
    this.alternates = const [],
  });

  final AssetEntity asset;
  final DateTime capturedAt;

  /// Other camera-roll shots taken within [CameraRollMatcher.clusterGap]
  /// of this one - a burst, or a couple of quick retakes - collapsed
  /// into this single suggestion rather than offered as separate ones.
  /// Empty for a shot that stood alone. The picker surfaces these as a
  /// "choose a different one from this moment" option rather than
  /// discarding them outright.
  final List<CameraRollMatch> alternates;

  /// The photo as it should be uploaded: a JPEG at most about 2048 px on
  /// its long side at quality 85, the same limits the app's own photo
  /// picker uses. The camera-roll original can be 5-10 MB, which every
  /// later view of the Trip would download. Re-encoding also leaves the
  /// original's location metadata behind. Null when the OS can't provide
  /// the image (for example an iCloud-only photo that fails to load).
  Future<List<int>?> uploadBytes() => asset.thumbnailDataWithSize(
    const ThumbnailSize(2048, 2048),
    format: ThumbnailFormat.jpeg,
    quality: 85,
  );
}

/// Finds and fetches camera-roll photos timestamped during a Trip, for
/// the Replay empty-timeline card's camera-roll match (Claude-Design "2b"
/// reference: "3 photos taken on this route"). Wraps `photo_manager` so
/// the rest of the feature doesn't need to know its API, and never
/// prompts for access on its own - [permissionState] only reads whatever
/// the OS already decided; a caller wanting to actually ask the user
/// calls [requestPermission] itself, from an explicit tap.
abstract final class CameraRollMatcher {
  /// A little slack either side of the Trip's recorded span: GPS start/
  /// end can lag the phone's clock by a few seconds, and a photo taken
  /// right as the Trip starts or ends shouldn't be missed over that.
  static const _slack = Duration(minutes: 2);

  /// A sanity cap on how many matches to fetch - a mislabeled or absurdly
  /// long "Trip" shouldn't try to pull in someone's entire camera roll.
  static const _maxMatches = 60;

  /// Consecutive shots this close together collapse into one suggestion
  /// (the first becomes the representative, the rest its [CameraRollMatch
  /// .alternates]) - a burst-mode sequence or a couple of quick retakes,
  /// rather than one suggestion per frame. Gap-based (measured between
  /// consecutive shots, not from a cluster's start or a fixed clock
  /// minute), so a burst that straddles a minute boundary still collapses
  /// correctly, and two unrelated shots that happen to land in the same
  /// minute but aren't actually close together don't.
  static const clusterGap = Duration(seconds: 60);

  /// How many suggested photos "Add to timeline" (the one-tap bulk
  /// action) will add at once. A Trip with more distinct clusters than
  /// this still has all of them available via "Choose" - this only
  /// caps the no-questions-asked bulk add, so it can't dump dozens of
  /// pins onto the timeline from a single tap.
  static const maxAutoAdd = 24;

  /// The current photo-library access, without prompting for it.
  static Future<PermissionState> permissionState() =>
      PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(),
      );

  /// Prompts for photo-library access if it hasn't been decided yet;
  /// returns the resulting state. A no-op dialog-wise if the user already
  /// denied it once (the OS won't re-prompt) - the caller should offer
  /// Settings in that case.
  static Future<PermissionState> requestPermission() =>
      PhotoManager.requestPermissionExtend();

  /// Opens this app's page in the OS Settings app, for when access was
  /// denied and the user wants to change their mind.
  static Future<void> openSettings() => PhotoManager.openSetting();

  /// Photos taken between [startedAt] and [endedAt] (plus [_slack] on
  /// each side), oldest first. Returns an empty list if access isn't
  /// granted or nothing matches - callers treat both the same way (fall
  /// back to the plain empty-timeline card), so this doesn't distinguish
  /// them; check [permissionState] first if that distinction matters.
  static Future<List<CameraRollMatch>> find({
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final state = await permissionState();
    if (!state.hasAccess) return const [];

    final filter = FilterOptionGroup(
      createTimeCond: DateTimeCond(
        min: startedAt.subtract(_slack),
        max: endedAt.add(_slack),
      ),
      orders: const [OrderOption(type: OrderOptionType.createDate, asc: true)],
    );
    List<AssetPathEntity> paths;
    try {
      paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
        filterOption: filter,
      );
    } on Object {
      return const [];
    }
    if (paths.isEmpty) return const [];
    final all = paths.first;
    final count = await all.assetCountAsync;
    if (count == 0) return const [];
    final assets = await all.getAssetListRange(
      start: 0,
      end: count > _maxMatches ? _maxMatches : count,
    );
    return _cluster([
      for (final asset in assets)
        CameraRollMatch(asset: asset, capturedAt: asset.createDateTime),
    ]);
  }

  /// Collapses a chronologically-sorted run of matches into one entry per
  /// cluster: consecutive shots no more than [clusterGap] apart join the
  /// same cluster, whose representative is the earliest shot in it and
  /// whose later shots become its [CameraRollMatch.alternates].
  static List<CameraRollMatch> _cluster(List<CameraRollMatch> sorted) {
    final result = <CameraRollMatch>[];
    var clusterStart = 0;
    for (var i = 1; i <= sorted.length; i++) {
      final closesCluster =
          i == sorted.length ||
          sorted[i].capturedAt.difference(sorted[i - 1].capturedAt) >
              clusterGap;
      if (!closesCluster) continue;
      final members = sorted.sublist(clusterStart, i);
      final representative = members.first;
      result.add(
        members.length == 1
            ? representative
            : CameraRollMatch(
                asset: representative.asset,
                capturedAt: representative.capturedAt,
                alternates: members.sublist(1),
              ),
      );
      clusterStart = i;
    }
    return result;
  }
}
