import 'dart:async';
import 'dart:io' show Platform;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../../notifications/application/push_providers.dart';
import '../data/arrival_notification_state.dart';
import 'arrival_notifier_provider.dart';

part 'notifications_prompt.g.dart';

/// Whether Home shows the "Turn on notifications" card. This is the one
/// place the app asks for notification permission: Home, on the first visit
/// on any phone (permission belongs to the phone, so a new phone is asked
/// again), once location has been dealt with in start-up, so two system
/// prompts never come back to back. Home also shows the system prompt itself
/// ([askOnHome]) when notifications are off. The card is the fallback: it
/// shows while the phone does not allow notifications, comes back three days
/// after a dismissal, and goes away once the phone allows them. Notifications cover county arrivals,
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

  static bool _askedThisLaunch = false;

  /// Shows the phone's own prompt, without waiting for the card's button,
  /// the first time Home is up in an app launch while notifications are
  /// off. iOS asks only once ever, so an answered phone is left to the
  /// card (which sends people to Settings). Android asks again until the
  /// person has refused twice; after that the call does nothing.
  Future<void> askOnHome() async {
    if (_askedThisLaunch || ref.read(currentUserIdProvider)() == null) return;
    _askedThisLaunch = true;
    try {
      final service = ref.read(arrivalNotifierServiceProvider);
      if (await service.isPermitted()) return;
      if (Platform.isIOS && await _state.permissionAsked()) return;
      await service.requestPermission();
      // The token's record on the server now carries the new answer.
      unawaited(ref.read(pushRegistrarProvider).sync());
    } on Object {
      // The card is still there as the fallback.
    }
    if (ref.mounted) ref.invalidateSelf();
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
