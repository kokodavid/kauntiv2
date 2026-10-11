// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_submit_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reports written without a connection, waiting to be sent. The state is
/// how many are waiting; [flush] sends them when there is signal.

@ProviderFor(FeedbackOutboxSync)
const feedbackOutboxSyncProvider = FeedbackOutboxSyncProvider._();

/// Reports written without a connection, waiting to be sent. The state is
/// how many are waiting; [flush] sends them when there is signal.
final class FeedbackOutboxSyncProvider
    extends $AsyncNotifierProvider<FeedbackOutboxSync, int> {
  /// Reports written without a connection, waiting to be sent. The state is
  /// how many are waiting; [flush] sends them when there is signal.
  const FeedbackOutboxSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedbackOutboxSyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedbackOutboxSyncHash();

  @$internal
  @override
  FeedbackOutboxSync create() => FeedbackOutboxSync();
}

String _$feedbackOutboxSyncHash() =>
    r'5e9be031f872a8ce9f0cee8b4380517216c4f835';

/// Reports written without a connection, waiting to be sent. The state is
/// how many are waiting; [flush] sends them when there is signal.

abstract class _$FeedbackOutboxSync extends $AsyncNotifier<int> {
  FutureOr<int> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>, int>,
              AsyncValue<int>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Files one report. The state is null until a report is sent, then the
/// outcome: filed (with its reference) or saved for when there is signal.

@ProviderFor(FeedbackSubmitter)
const feedbackSubmitterProvider = FeedbackSubmitterProvider._();

/// Files one report. The state is null until a report is sent, then the
/// outcome: filed (with its reference) or saved for when there is signal.
final class FeedbackSubmitterProvider
    extends $AsyncNotifierProvider<FeedbackSubmitter, FeedbackSubmission?> {
  /// Files one report. The state is null until a report is sent, then the
  /// outcome: filed (with its reference) or saved for when there is signal.
  const FeedbackSubmitterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedbackSubmitterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedbackSubmitterHash();

  @$internal
  @override
  FeedbackSubmitter create() => FeedbackSubmitter();
}

String _$feedbackSubmitterHash() => r'bbd00a6660424eb08b9b84545e63ff46e8e476ea';

/// Files one report. The state is null until a report is sent, then the
/// outcome: filed (with its reference) or saved for when there is signal.

abstract class _$FeedbackSubmitter extends $AsyncNotifier<FeedbackSubmission?> {
  FutureOr<FeedbackSubmission?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<FeedbackSubmission?>, FeedbackSubmission?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FeedbackSubmission?>, FeedbackSubmission?>,
              AsyncValue<FeedbackSubmission?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
