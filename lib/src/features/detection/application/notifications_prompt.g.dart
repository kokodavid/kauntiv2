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
/// prompts never come back to back. It shows while the phone does not allow
/// notifications and the card has not been dismissed on this phone, and goes
/// away once the phone allows them. Notifications cover county arrivals,
/// replies to photos and trips, and announcements, so it no longer depends
/// on the county-nudge switch or on automatic detection.

@ProviderFor(NotificationsPrompt)
const notificationsPromptProvider = NotificationsPromptProvider._();

/// Whether Home shows the "Turn on notifications" card. This is the one
/// place the app asks for notification permission: Home, on the first visit
/// on any phone (permission belongs to the phone, so a new phone is asked
/// again), once location has been dealt with in start-up, so two system
/// prompts never come back to back. It shows while the phone does not allow
/// notifications and the card has not been dismissed on this phone, and goes
/// away once the phone allows them. Notifications cover county arrivals,
/// replies to photos and trips, and announcements, so it no longer depends
/// on the county-nudge switch or on automatic detection.
final class NotificationsPromptProvider
    extends $AsyncNotifierProvider<NotificationsPrompt, bool> {
  /// Whether Home shows the "Turn on notifications" card. This is the one
  /// place the app asks for notification permission: Home, on the first visit
  /// on any phone (permission belongs to the phone, so a new phone is asked
  /// again), once location has been dealt with in start-up, so two system
  /// prompts never come back to back. It shows while the phone does not allow
  /// notifications and the card has not been dismissed on this phone, and goes
  /// away once the phone allows them. Notifications cover county arrivals,
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
    r'b0879e1f6e73da5b3714e78e03c6829622e4081c';

/// Whether Home shows the "Turn on notifications" card. This is the one
/// place the app asks for notification permission: Home, on the first visit
/// on any phone (permission belongs to the phone, so a new phone is asked
/// again), once location has been dealt with in start-up, so two system
/// prompts never come back to back. It shows while the phone does not allow
/// notifications and the card has not been dismissed on this phone, and goes
/// away once the phone allows them. Notifications cover county arrivals,
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
