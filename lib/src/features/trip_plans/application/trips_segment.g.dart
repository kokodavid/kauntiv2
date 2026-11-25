// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trips_segment.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which half of the Trips tab is showing. The tab always opens on
/// Recorded; after that only the user (or a notification that points at
/// plans) changes it. Not kept between sessions.

@ProviderFor(TripsSegmentChoice)
const tripsSegmentChoiceProvider = TripsSegmentChoiceProvider._();

/// Which half of the Trips tab is showing. The tab always opens on
/// Recorded; after that only the user (or a notification that points at
/// plans) changes it. Not kept between sessions.
final class TripsSegmentChoiceProvider
    extends $NotifierProvider<TripsSegmentChoice, TripsSegment> {
  /// Which half of the Trips tab is showing. The tab always opens on
  /// Recorded; after that only the user (or a notification that points at
  /// plans) changes it. Not kept between sessions.
  const TripsSegmentChoiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripsSegmentChoiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripsSegmentChoiceHash();

  @$internal
  @override
  TripsSegmentChoice create() => TripsSegmentChoice();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripsSegment value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripsSegment>(value),
    );
  }
}

String _$tripsSegmentChoiceHash() =>
    r'c2f7d58e2c007e7cbe4b6672e0bb1683816ca06a';

/// Which half of the Trips tab is showing. The tab always opens on
/// Recorded; after that only the user (or a notification that points at
/// plans) changes it. Not kept between sessions.

abstract class _$TripsSegmentChoice extends $Notifier<TripsSegment> {
  TripsSegment build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<TripsSegment, TripsSegment>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TripsSegment, TripsSegment>,
              TripsSegment,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
