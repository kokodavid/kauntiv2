// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_permission_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// True when the phone has notifications switched off for Kaunti47, so
/// Settings can say so and offer a way to the phone's settings. False when
/// allowed, not asked yet, or push is not set up in this build.

@ProviderFor(notificationsBlocked)
const notificationsBlockedProvider = NotificationsBlockedProvider._();

/// True when the phone has notifications switched off for Kaunti47, so
/// Settings can say so and offer a way to the phone's settings. False when
/// allowed, not asked yet, or push is not set up in this build.

final class NotificationsBlockedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// True when the phone has notifications switched off for Kaunti47, so
  /// Settings can say so and offer a way to the phone's settings. False when
  /// allowed, not asked yet, or push is not set up in this build.
  const NotificationsBlockedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsBlockedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsBlockedHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return notificationsBlocked(ref);
  }
}

String _$notificationsBlockedHash() =>
    r'78c7aae45d399b5d1ebfd99ac909b645809f771d';
