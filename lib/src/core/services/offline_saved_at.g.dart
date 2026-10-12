// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_saved_at.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// When the copy a screen is showing was saved, set by the screen that
/// shows one (Home). While set, the offline banner switches to its Home
/// form: "You're offline · Saved 9:41 AM" with a Retry.

@ProviderFor(OfflineSavedAt)
const offlineSavedAtProvider = OfflineSavedAtProvider._();

/// When the copy a screen is showing was saved, set by the screen that
/// shows one (Home). While set, the offline banner switches to its Home
/// form: "You're offline · Saved 9:41 AM" with a Retry.
final class OfflineSavedAtProvider
    extends $NotifierProvider<OfflineSavedAt, DateTime?> {
  /// When the copy a screen is showing was saved, set by the screen that
  /// shows one (Home). While set, the offline banner switches to its Home
  /// form: "You're offline · Saved 9:41 AM" with a Retry.
  const OfflineSavedAtProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlineSavedAtProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlineSavedAtHash();

  @$internal
  @override
  OfflineSavedAt create() => OfflineSavedAt();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$offlineSavedAtHash() => r'6f9c0fb909e7d55b05ac33f7db11055aab7e7963';

/// When the copy a screen is showing was saved, set by the screen that
/// shows one (Home). While set, the offline banner switches to its Home
/// form: "You're offline · Saved 9:41 AM" with a Retry.

abstract class _$OfflineSavedAt extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
