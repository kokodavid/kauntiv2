// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drains the Journey upload queue; the state counts uploads this session.

@ProviderFor(JourneySync)
const journeySyncProvider = JourneySyncProvider._();

/// Drains the Journey upload queue; the state counts uploads this session.
final class JourneySyncProvider extends $NotifierProvider<JourneySync, int> {
  /// Drains the Journey upload queue; the state counts uploads this session.
  const JourneySyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeySyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeySyncHash();

  @$internal
  @override
  JourneySync create() => JourneySync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$journeySyncHash() => r'088f31203aa67d87c2c4da79282473d07410dc34';

/// Drains the Journey upload queue; the state counts uploads this session.

abstract class _$JourneySync extends $Notifier<int> {
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
