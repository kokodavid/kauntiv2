// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trips_segment.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which half of the Trips tab is showing. Null until the default has been
/// worked out (see [resolveDefault]); after that only the user changes it,
/// so a refresh never flips the tab under them. Not kept between sessions.

@ProviderFor(TripsSegmentChoice)
const tripsSegmentChoiceProvider = TripsSegmentChoiceProvider._();

/// Which half of the Trips tab is showing. Null until the default has been
/// worked out (see [resolveDefault]); after that only the user changes it,
/// so a refresh never flips the tab under them. Not kept between sessions.
final class TripsSegmentChoiceProvider
    extends $NotifierProvider<TripsSegmentChoice, TripsSegment?> {
  /// Which half of the Trips tab is showing. Null until the default has been
  /// worked out (see [resolveDefault]); after that only the user changes it,
  /// so a refresh never flips the tab under them. Not kept between sessions.
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
  Override overrideWithValue(TripsSegment? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripsSegment?>(value),
    );
  }
}

String _$tripsSegmentChoiceHash() =>
    r'c4b01ed5ae617d1a1e3b5fce51d1fc07b6224150';

/// Which half of the Trips tab is showing. Null until the default has been
/// worked out (see [resolveDefault]); after that only the user changes it,
/// so a refresh never flips the tab under them. Not kept between sessions.

abstract class _$TripsSegmentChoice extends $Notifier<TripsSegment?> {
  TripsSegment? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<TripsSegment?, TripsSegment?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TripsSegment?, TripsSegment?>,
              TripsSegment?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
