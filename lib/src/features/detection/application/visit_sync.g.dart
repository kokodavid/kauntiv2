// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The upload queue for the signed-in user, or null when Supabase isn't
/// configured for this build.

@ProviderFor(visitSyncQueue)
const visitSyncQueueProvider = VisitSyncQueueProvider._();

/// The upload queue for the signed-in user, or null when Supabase isn't
/// configured for this build.

final class VisitSyncQueueProvider
    extends
        $FunctionalProvider<VisitSyncQueue?, VisitSyncQueue?, VisitSyncQueue?>
    with $Provider<VisitSyncQueue?> {
  /// The upload queue for the signed-in user, or null when Supabase isn't
  /// configured for this build.
  const VisitSyncQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visitSyncQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visitSyncQueueHash();

  @$internal
  @override
  $ProviderElement<VisitSyncQueue?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VisitSyncQueue? create(Ref ref) {
    return visitSyncQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VisitSyncQueue? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VisitSyncQueue?>(value),
    );
  }
}

String _$visitSyncQueueHash() => r'c69c3a8130abfa54ecd24e4e0f9e3b058c77d488';

/// Drains queued visits and keeps the rest of the app in step. The state
/// counts visits synced this session, so screens that show visit state
/// can watch it and reload when it changes.

@ProviderFor(VisitSync)
const visitSyncProvider = VisitSyncProvider._();

/// Drains queued visits and keeps the rest of the app in step. The state
/// counts visits synced this session, so screens that show visit state
/// can watch it and reload when it changes.
final class VisitSyncProvider extends $NotifierProvider<VisitSync, int> {
  /// Drains queued visits and keeps the rest of the app in step. The state
  /// counts visits synced this session, so screens that show visit state
  /// can watch it and reload when it changes.
  const VisitSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visitSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visitSyncHash();

  @$internal
  @override
  VisitSync create() => VisitSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$visitSyncHash() => r'7c892f75aabf18dedebb6506f7a3783758cdf418';

/// Drains queued visits and keeps the rest of the app in step. The state
/// counts visits synced this session, so screens that show visit state
/// can watch it and reload when it changes.

abstract class _$VisitSync extends $Notifier<int> {
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
