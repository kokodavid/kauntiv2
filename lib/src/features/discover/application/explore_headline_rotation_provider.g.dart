// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_headline_rotation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which liked type leads the Places sentence this app launch: a counter
/// kept on this phone that goes up by one per launch, so the sentence takes
/// the nearby types in turn. Kept alive, so it holds still for the whole
/// session. Local only; 0 when storage is unavailable.

@ProviderFor(exploreHeadlineRotation)
const exploreHeadlineRotationProvider = ExploreHeadlineRotationProvider._();

/// Which liked type leads the Places sentence this app launch: a counter
/// kept on this phone that goes up by one per launch, so the sentence takes
/// the nearby types in turn. Kept alive, so it holds still for the whole
/// session. Local only; 0 when storage is unavailable.

final class ExploreHeadlineRotationProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Which liked type leads the Places sentence this app launch: a counter
  /// kept on this phone that goes up by one per launch, so the sentence takes
  /// the nearby types in turn. Kept alive, so it holds still for the whole
  /// session. Local only; 0 when storage is unavailable.
  const ExploreHeadlineRotationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreHeadlineRotationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreHeadlineRotationHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return exploreHeadlineRotation(ref);
  }
}

String _$exploreHeadlineRotationHash() =>
    r'842c2787e69dc87b93e6494150d8666033364d52';
