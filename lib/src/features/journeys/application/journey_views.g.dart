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

/// A Trip's uploaded photos, for Replay - empty (not an error) once the
/// Trip itself is still only on this phone, since its photos haven't had
/// anything to upload against yet either.

@ProviderFor(journeyMedia)
const journeyMediaProvider = JourneyMediaFamily._();

/// A Trip's uploaded photos, for Replay - empty (not an error) once the
/// Trip itself is still only on this phone, since its photos haven't had
/// anything to upload against yet either.

final class JourneyMediaProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<JourneyMediaItem>>,
          List<JourneyMediaItem>,
          FutureOr<List<JourneyMediaItem>>
        >
    with
        $FutureModifier<List<JourneyMediaItem>>,
        $FutureProvider<List<JourneyMediaItem>> {
  /// A Trip's uploaded photos, for Replay - empty (not an error) once the
  /// Trip itself is still only on this phone, since its photos haven't had
  /// anything to upload against yet either.
  const JourneyMediaProvider._({
    required JourneyMediaFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'journeyMediaProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$journeyMediaHash();

  @override
  String toString() {
    return r'journeyMediaProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<JourneyMediaItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<JourneyMediaItem>> create(Ref ref) {
    final argument = this.argument as String;
    return journeyMedia(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is JourneyMediaProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$journeyMediaHash() => r'ea89794328bb803cd19c9ffae9db90a74e0b4c90';

/// A Trip's uploaded photos, for Replay - empty (not an error) once the
/// Trip itself is still only on this phone, since its photos haven't had
/// anything to upload against yet either.

final class JourneyMediaFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<JourneyMediaItem>>, String> {
  const JourneyMediaFamily._()
    : super(
        retry: null,
        name: r'journeyMediaProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A Trip's uploaded photos, for Replay - empty (not an error) once the
  /// Trip itself is still only on this phone, since its photos haven't had
  /// anything to upload against yet either.

  JourneyMediaProvider call(String id) =>
      JourneyMediaProvider._(argument: id, from: this);

  @override
  String toString() => r'journeyMediaProvider';
}
