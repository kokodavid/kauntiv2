import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'offline_saved_at.g.dart';

/// When the copy a screen is showing was saved, set by the screen that
/// shows one (Home). While set, the offline banner switches to its Home
/// form: "You're offline · Saved 9:41 AM" with a Retry.
@Riverpod(keepAlive: true)
class OfflineSavedAt extends _$OfflineSavedAt {
  @override
  DateTime? build() => null;

  void set(DateTime? savedAt) => state = savedAt;
}
