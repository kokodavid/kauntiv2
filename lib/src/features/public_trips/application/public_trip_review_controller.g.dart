// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_trip_review_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The review-and-submit flow for one trip: pick moments and photos, ask
/// the server for the sanitized preview, then accept the terms and submit.

@ProviderFor(PublicTripReviewController)
const publicTripReviewControllerProvider = PublicTripReviewControllerFamily._();

/// The review-and-submit flow for one trip: pick moments and photos, ask
/// the server for the sanitized preview, then accept the terms and submit.
final class PublicTripReviewControllerProvider
    extends
        $AsyncNotifierProvider<
          PublicTripReviewController,
          PublicTripReviewState
        > {
  /// The review-and-submit flow for one trip: pick moments and photos, ask
  /// the server for the sanitized preview, then accept the terms and submit.
  const PublicTripReviewControllerProvider._({
    required PublicTripReviewControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'publicTripReviewControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$publicTripReviewControllerHash();

  @override
  String toString() {
    return r'publicTripReviewControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PublicTripReviewController create() => PublicTripReviewController();

  @override
  bool operator ==(Object other) {
    return other is PublicTripReviewControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$publicTripReviewControllerHash() =>
    r'c2510246f983d7b0ca2bab814d13ed330f045472';

/// The review-and-submit flow for one trip: pick moments and photos, ask
/// the server for the sanitized preview, then accept the terms and submit.

final class PublicTripReviewControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PublicTripReviewController,
          AsyncValue<PublicTripReviewState>,
          PublicTripReviewState,
          FutureOr<PublicTripReviewState>,
          String
        > {
  const PublicTripReviewControllerFamily._()
    : super(
        retry: null,
        name: r'publicTripReviewControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The review-and-submit flow for one trip: pick moments and photos, ask
  /// the server for the sanitized preview, then accept the terms and submit.

  PublicTripReviewControllerProvider call(String journeyId) =>
      PublicTripReviewControllerProvider._(argument: journeyId, from: this);

  @override
  String toString() => r'publicTripReviewControllerProvider';
}

/// The review-and-submit flow for one trip: pick moments and photos, ask
/// the server for the sanitized preview, then accept the terms and submit.

abstract class _$PublicTripReviewController
    extends $AsyncNotifier<PublicTripReviewState> {
  late final _$args = ref.$arg as String;
  String get journeyId => _$args;

  FutureOr<PublicTripReviewState> build(String journeyId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref
            as $Ref<AsyncValue<PublicTripReviewState>, PublicTripReviewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PublicTripReviewState>,
                PublicTripReviewState
              >,
              AsyncValue<PublicTripReviewState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
