// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_prompt.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether Home shows the "Turn on notifications" card: for someone whose
/// phone does not allow notifications yet (an older install that never saw
/// the setup step, or a "Not now" there), who still has county nudges on
/// and automatic detection, has not dismissed it, and has opened Home at
/// least [notificationsPromptMinSessions] times. It goes away once the
/// phone allows notifications.

@ProviderFor(NotificationsPrompt)
const notificationsPromptProvider = NotificationsPromptProvider._();

/// Whether Home shows the "Turn on notifications" card: for someone whose
/// phone does not allow notifications yet (an older install that never saw
/// the setup step, or a "Not now" there), who still has county nudges on
/// and automatic detection, has not dismissed it, and has opened Home at
/// least [notificationsPromptMinSessions] times. It goes away once the
/// phone allows notifications.
final class NotificationsPromptProvider
    extends $AsyncNotifierProvider<NotificationsPrompt, bool> {
  /// Whether Home shows the "Turn on notifications" card: for someone whose
  /// phone does not allow notifications yet (an older install that never saw
  /// the setup step, or a "Not now" there), who still has county nudges on
  /// and automatic detection, has not dismissed it, and has opened Home at
  /// least [notificationsPromptMinSessions] times. It goes away once the
  /// phone allows notifications.
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
    r'f3f4dfe5021ce0f9edda432fa5e950a98ccec70f';

/// Whether Home shows the "Turn on notifications" card: for someone whose
/// phone does not allow notifications yet (an older install that never saw
/// the setup step, or a "Not now" there), who still has county nudges on
/// and automatic detection, has not dismissed it, and has opened Home at
/// least [notificationsPromptMinSessions] times. It goes away once the
/// phone allows notifications.

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
