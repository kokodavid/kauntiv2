// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_key_moments.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Kaunti47 places as map pins for the map while recording (same pins as
/// Home). Kept for the session: places change rarely.

@ProviderFor(journeyMapPlaces)
const journeyMapPlacesProvider = JourneyMapPlacesProvider._();

/// Kaunti47 places as map pins for the map while recording (same pins as
/// Home). Kept for the session: places change rarely.

final class JourneyMapPlacesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MapPlace>>,
          List<MapPlace>,
          FutureOr<List<MapPlace>>
        >
    with $FutureModifier<List<MapPlace>>, $FutureProvider<List<MapPlace>> {
  /// Kaunti47 places as map pins for the map while recording (same pins as
  /// Home). Kept for the session: places change rarely.
  const JourneyMapPlacesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyMapPlacesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyMapPlacesHash();

  @$internal
  @override
  $FutureProviderElement<List<MapPlace>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MapPlace>> create(Ref ref) {
    return journeyMapPlaces(ref);
  }
}

String _$journeyMapPlacesHash() => r'27a21d896568d8f0f668d1106f0c153755141e7d';

/// A Journey's key moments, in replay order: recording breaks, long stops,
/// county crossings (from the bundled boundaries, so offline too), photos
/// and the Trip's elevation peak.

@ProviderFor(journeyMoments)
const journeyMomentsProvider = JourneyMomentsFamily._();

/// A Journey's key moments, in replay order: recording breaks, long stops,
/// county crossings (from the bundled boundaries, so offline too), photos
/// and the Trip's elevation peak.

final class JourneyMomentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<JourneyMoment>>,
          List<JourneyMoment>,
          FutureOr<List<JourneyMoment>>
        >
    with
        $FutureModifier<List<JourneyMoment>>,
        $FutureProvider<List<JourneyMoment>> {
  /// A Journey's key moments, in replay order: recording breaks, long stops,
  /// county crossings (from the bundled boundaries, so offline too), photos
  /// and the Trip's elevation peak.
  const JourneyMomentsProvider._({
    required JourneyMomentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'journeyMomentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$journeyMomentsHash();

  @override
  String toString() {
    return r'journeyMomentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<JourneyMoment>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<JourneyMoment>> create(Ref ref) {
    final argument = this.argument as String;
    return journeyMoments(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is JourneyMomentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$journeyMomentsHash() => r'a90795c8081acb44e9e38cde1d89c68ba88264c6';

/// A Journey's key moments, in replay order: recording breaks, long stops,
/// county crossings (from the bundled boundaries, so offline too), photos
/// and the Trip's elevation peak.

final class JourneyMomentsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<JourneyMoment>>, String> {
  const JourneyMomentsFamily._()
    : super(
        retry: null,
        name: r'journeyMomentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A Journey's key moments, in replay order: recording breaks, long stops,
  /// county crossings (from the bundled boundaries, so offline too), photos
  /// and the Trip's elevation peak.

  JourneyMomentsProvider call(String id) =>
      JourneyMomentsProvider._(argument: id, from: this);

  @override
  String toString() => r'journeyMomentsProvider';
}
