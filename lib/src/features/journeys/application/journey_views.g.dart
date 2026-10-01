// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_views.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The active Journey's route as it's recorded (empty when none).

@ProviderFor(activeJourneyRoute)
const activeJourneyRouteProvider = ActiveJourneyRouteProvider._();

/// The active Journey's route as it's recorded (empty when none).

final class ActiveJourneyRouteProvider
    extends
        $FunctionalProvider<
          AsyncValue<JourneyRoute>,
          JourneyRoute,
          Stream<JourneyRoute>
        >
    with $FutureModifier<JourneyRoute>, $StreamProvider<JourneyRoute> {
  /// The active Journey's route as it's recorded (empty when none).
  const ActiveJourneyRouteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeJourneyRouteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeJourneyRouteHash();

  @$internal
  @override
  $StreamProviderElement<JourneyRoute> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<JourneyRoute> create(Ref ref) {
    return activeJourneyRoute(ref);
  }
}

String _$activeJourneyRouteHash() =>
    r'e777e18f186fd176d08eaf4cdf8ee68c4b4d3c6e';

@ProviderFor(journeyDetail)
const journeyDetailProvider = JourneyDetailFamily._();

final class JourneyDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<JourneyDetail>,
          JourneyDetail,
          FutureOr<JourneyDetail>
        >
    with $FutureModifier<JourneyDetail>, $FutureProvider<JourneyDetail> {
  const JourneyDetailProvider._({
    required JourneyDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'journeyDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$journeyDetailHash();

  @override
  String toString() {
    return r'journeyDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<JourneyDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<JourneyDetail> create(Ref ref) {
    final argument = this.argument as String;
    return journeyDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is JourneyDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$journeyDetailHash() => r'e54b7a37b652b598892277065f063b1533e01198';

final class JourneyDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<JourneyDetail>, String> {
  const JourneyDetailFamily._()
    : super(
        retry: null,
        name: r'journeyDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  JourneyDetailProvider call(String id) =>
      JourneyDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'journeyDetailProvider';
}
