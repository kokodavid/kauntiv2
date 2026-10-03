import 'package:photo_manager/photo_manager.dart';

/// One camera-roll photo whose timestamp falls inside a Trip's recorded
/// span, offered for adding to Replay's timeline.
class CameraRollMatch {
  const CameraRollMatch({required this.asset, required this.capturedAt});

  final AssetEntity asset;
  final DateTime capturedAt;
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
    return [
      for (final asset in assets)
        CameraRollMatch(asset: asset, capturedAt: asset.createDateTime),
    ];
  }
}
