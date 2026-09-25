// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_recorder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The active Journey for the signed-in account: Pro-gated start, pause,
/// resume and finish, and recovery after a restart. Finishing queues the
/// upload. No UI calls this yet (Journeys step 4).
///
/// Bound to one account: when the signed-in account changes, a recording
/// Journey is paused for its owner and let go, so the next account never
/// sees or continues it.

@ProviderFor(JourneyRecorder)
const journeyRecorderProvider = JourneyRecorderProvider._();

/// The active Journey for the signed-in account: Pro-gated start, pause,
/// resume and finish, and recovery after a restart. Finishing queues the
/// upload. No UI calls this yet (Journeys step 4).
///
/// Bound to one account: when the signed-in account changes, a recording
/// Journey is paused for its owner and let go, so the next account never
/// sees or continues it.
final class JourneyRecorderProvider
    extends $NotifierProvider<JourneyRecorder, LocalJourneySession?> {
  /// The active Journey for the signed-in account: Pro-gated start, pause,
  /// resume and finish, and recovery after a restart. Finishing queues the
  /// upload. No UI calls this yet (Journeys step 4).
  ///
  /// Bound to one account: when the signed-in account changes, a recording
  /// Journey is paused for its owner and let go, so the next account never
  /// sees or continues it.
  const JourneyRecorderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyRecorderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyRecorderHash();

  @$internal
  @override
  JourneyRecorder create() => JourneyRecorder();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalJourneySession? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalJourneySession?>(value),
    );
  }
}

String _$journeyRecorderHash() => r'd926412816cd56c611eaf566cf6161f527de56c3';

/// The active Journey for the signed-in account: Pro-gated start, pause,
/// resume and finish, and recovery after a restart. Finishing queues the
/// upload. No UI calls this yet (Journeys step 4).
///
/// Bound to one account: when the signed-in account changes, a recording
/// Journey is paused for its owner and let go, so the next account never
/// sees or continues it.

abstract class _$JourneyRecorder extends $Notifier<LocalJourneySession?> {
  LocalJourneySession? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<LocalJourneySession?, LocalJourneySession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocalJourneySession?, LocalJourneySession?>,
              LocalJourneySession?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

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

String _$journeySyncHash() => r'0edfa6e77ca098fbd991723b29426cb9cb31884c';

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
