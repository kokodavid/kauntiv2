// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_prompt.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(NotificationsPrompt)
const notificationsPromptProvider = NotificationsPromptProvider._();

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
final class NotificationsPromptProvider
    extends $AsyncNotifierProvider<NotificationsPrompt, bool> {
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
  const NotificationsPromptProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsPromptProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsPromptHash();

  @$internal
  @override
  NotificationsPrompt create() => NotificationsPrompt();
}

String _$notificationsPromptHash() =>
    r'22f9d28d1c9443451e848d154539303cb4a03c7c';

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

abstract class _$NotificationsPrompt extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
