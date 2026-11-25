// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_recordings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// My recorded Trips for a plan, by day id. Empty when they can't be read,
/// so days simply show Start trip.

@ProviderFor(planRecordings)
const planRecordingsProvider = PlanRecordingsFamily._();

/// My recorded Trips for a plan, by day id. Empty when they can't be read,
/// so days simply show Start trip.

final class PlanRecordingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, PlanDayRecording>>,
          Map<String, PlanDayRecording>,
          FutureOr<Map<String, PlanDayRecording>>
        >
    with
        $FutureModifier<Map<String, PlanDayRecording>>,
        $FutureProvider<Map<String, PlanDayRecording>> {
  /// My recorded Trips for a plan, by day id. Empty when they can't be read,
  /// so days simply show Start trip.
  const PlanRecordingsProvider._({
    required PlanRecordingsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'planRecordingsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planRecordingsHash();

  @override
  String toString() {
    return r'planRecordingsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, PlanDayRecording>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, PlanDayRecording>> create(Ref ref) {
    final argument = this.argument as String;
    return planRecordings(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlanRecordingsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planRecordingsHash() => r'db8f49afd678f81ac1d36a372a29c05b57457d88';

/// My recorded Trips for a plan, by day id. Empty when they can't be read,
/// so days simply show Start trip.

final class PlanRecordingsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Map<String, PlanDayRecording>>,
          String
        > {
  const PlanRecordingsFamily._()
    : super(
        retry: null,
        name: r'planRecordingsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// My recorded Trips for a plan, by day id. Empty when they can't be read,
  /// so days simply show Start trip.

  PlanRecordingsProvider call(String planId) =>
      PlanRecordingsProvider._(argument: planId, from: this);

  @override
  String toString() => r'planRecordingsProvider';
}
