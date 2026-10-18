import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../data/arrival_notification_state.dart';
import 'arrival_notifier_provider.dart';

part 'notifications_prompt.g.dart';

/// Whether Home shows the "Turn on notifications" card. This is the one
/// place the app asks for notification permission: Home, on the first visit
/// on any phone (permission belongs to the phone, so a new phone is asked
/// again), once location has been dealt with in start-up, so two system
/// prompts never come back to back. It shows while the phone does not allow
/// notifications and the card has not been dismissed on this phone, and goes
/// away once the phone allows them. Notifications cover county arrivals,
/// replies to photos and trips, and announcements, so it no longer depends
/// on the county-nudge switch or on automatic detection.
@Riverpod(keepAlive: true)
class NotificationsPrompt extends _$NotificationsPrompt {
  static const _state = ArrivalNotificationState();

  @override
  Future<bool> build() async {
    if (ref.read(currentUserIdProvider)() == null) return false;
    try {
      if (await _state.promptDismissed()) return false;
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
