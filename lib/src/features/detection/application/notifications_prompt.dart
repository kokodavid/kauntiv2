import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../../profile/application/interests_providers.dart';
import '../../profile/application/profile_settings_providers.dart';
import '../../profile/domain/profile_settings.dart';
import '../data/arrival_notification_state.dart';
import 'arrival_notifier_provider.dart';

part 'notifications_prompt.g.dart';

/// How many app sessions reach Home before the card first appears, so
/// someone who just finished setup is not asked twice in a row.
const notificationsPromptMinSessions = 2;

/// Whether Home shows the "Turn on notifications" card: for someone whose
/// phone does not allow notifications yet (an older install that never saw
/// the setup step, or a "Not now" there), who still has county nudges on
/// and automatic detection, has not dismissed it, and has opened Home at
/// least [notificationsPromptMinSessions] times. It goes away once the
/// phone allows notifications.
@Riverpod(keepAlive: true)
class NotificationsPrompt extends _$NotificationsPrompt {
  static const _state = ArrivalNotificationState();

  @override
  Future<bool> build() async {
    if (ref.read(currentUserIdProvider)() == null) return false;
    final sessions = await ref.watch(interestsSessionCountProvider.future);
    if (sessions < notificationsPromptMinSessions) return false;
    try {
      if (await _state.promptDismissed()) return false;
      final settings = await ref.watch(
        profileSettingsControllerProvider.future,
      );
      if (settings.locationMode != LocationMode.automatic ||
          !settings.notifyCountyNudges) {
        return false;
      }
      return !await ref.read(arrivalNotifierServiceProvider).isPermitted();
    } on Object {
      return false;
    }
  }

  /// The card's button. The first time, the OS prompt; after the phone has
  /// already been asked (it will not show the prompt again), the app's
  /// settings via [openSettings].
  Future<void> turnOn({required void Function() openSettings}) async {
    try {
      if (await _state.permissionAsked()) {
        openSettings();
        return;
      }
      await ref.read(arrivalNotifierServiceProvider).requestPermission();
    } on Object {
      // The card stays; the next tap tries again.
    }
    if (ref.mounted) ref.invalidateSelf();
  }

  /// Back from the phone's settings: hides the card if it was allowed.
  void recheck() => ref.invalidateSelf();

  /// Hides the card for good.
  Future<void> dismiss() async {
    try {
      await _state.dismissPrompt();
    } on Object {
      // Worst case the card shows once more.
    }
    if (ref.mounted) state = const AsyncData(false);
  }
}
