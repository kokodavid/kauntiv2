// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_screen_presence.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How many full-screen "You're offline" states are showing right now. The
/// banner steps aside while one is, so the message isn't said twice.

@ProviderFor(OfflineScreenPresence)
const offlineScreenPresenceProvider = OfflineScreenPresenceProvider._();

/// How many full-screen "You're offline" states are showing right now. The
/// banner steps aside while one is, so the message isn't said twice.
final class OfflineScreenPresenceProvider
    extends $NotifierProvider<OfflineScreenPresence, int> {
  /// How many full-screen "You're offline" states are showing right now. The
  /// banner steps aside while one is, so the message isn't said twice.
  const OfflineScreenPresenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlineScreenPresenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlineScreenPresenceHash();

  @$internal
  @override
  OfflineScreenPresence create() => OfflineScreenPresence();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$offlineScreenPresenceHash() =>
    r'10ba069dce250ec4a34e409e794eea0d659088a3';

/// How many full-screen "You're offline" states are showing right now. The
/// banner steps aside while one is, so the message isn't said twice.

abstract class _$OfflineScreenPresence extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Whether the offline banner should stay hidden: a full-screen offline
/// state is up and the phone is still cut off. Once the connection returns
/// the banner is free to show "Back online".

@ProviderFor(offlineBannerSuppressed)
const offlineBannerSuppressedProvider = OfflineBannerSuppressedProvider._();

/// Whether the offline banner should stay hidden: a full-screen offline
/// state is up and the phone is still cut off. Once the connection returns
/// the banner is free to show "Back online".

final class OfflineBannerSuppressedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the offline banner should stay hidden: a full-screen offline
  /// state is up and the phone is still cut off. Once the connection returns
  /// the banner is free to show "Back online".
  const OfflineBannerSuppressedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlineBannerSuppressedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlineBannerSuppressedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return offlineBannerSuppressed(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$offlineBannerSuppressedHash() =>
    r'76f87a1e3134df77169b67423c919b83bedf8c0b';
