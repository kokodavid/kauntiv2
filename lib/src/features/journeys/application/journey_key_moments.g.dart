// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_key_moments.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user's saved places, for spotting them along a replay.
/// Empty offline or without Supabase: the other moments still work.

@ProviderFor(journeySavedPlaces)
const journeySavedPlacesProvider = JourneySavedPlacesProvider._();

/// The signed-in user's saved places, for spotting them along a replay.
/// Empty offline or without Supabase: the other moments still work.

final class JourneySavedPlacesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<JourneyPlaceMark>>,
          List<JourneyPlaceMark>,
          FutureOr<List<JourneyPlaceMark>>
        >
    with
        $FutureModifier<List<JourneyPlaceMark>>,
        $FutureProvider<List<JourneyPlaceMark>> {
  /// The signed-in user's saved places, for spotting them along a replay.
  /// Empty offline or without Supabase: the other moments still work.
  const JourneySavedPlacesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeySavedPlacesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeySavedPlacesHash();

  @$internal
  @override
  $FutureProviderElement<List<JourneyPlaceMark>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<JourneyPlaceMark>> create(Ref ref) {
    return journeySavedPlaces(ref);
  }
}

String _$journeySavedPlacesHash() =>
    r'b2d68ced5838c6b9a37e093da097bf87926e69ab';

/// A Journey's key moments, in replay order: recording breaks, long stops,
/// county crossings (from the bundled boundaries, so offline too) and
/// saved places passed.

@ProviderFor(journeyMoments)
const journeyMomentsProvider = JourneyMomentsFamily._();

/// A Journey's key moments, in replay order: recording breaks, long stops,
/// county crossings (from the bundled boundaries, so offline too) and
/// saved places passed.

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
  /// county crossings (from the bundled boundaries, so offline too) and
  /// saved places passed.
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

String _$journeyMomentsHash() => r'31fd8d7ffc455e60234d8143a2dd10a19553cd06';

/// A Journey's key moments, in replay order: recording breaks, long stops,
/// county crossings (from the bundled boundaries, so offline too) and
/// saved places passed.

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
  /// county crossings (from the bundled boundaries, so offline too) and
  /// saved places passed.

  JourneyMomentsProvider call(String id) =>
      JourneyMomentsProvider._(argument: id, from: this);

  @override
  String toString() => r'journeyMomentsProvider';
}
