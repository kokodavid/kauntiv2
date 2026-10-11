// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Null when the build has no Supabase. Tests override it.

@ProviderFor(feedbackRepository)
const feedbackRepositoryProvider = FeedbackRepositoryProvider._();

/// Null when the build has no Supabase. Tests override it.

final class FeedbackRepositoryProvider
    extends
        $FunctionalProvider<
          FeedbackRepository?,
          FeedbackRepository?,
          FeedbackRepository?
        >
    with $Provider<FeedbackRepository?> {
  /// Null when the build has no Supabase. Tests override it.
  const FeedbackRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedbackRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedbackRepositoryHash();

  @$internal
  @override
  $ProviderElement<FeedbackRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FeedbackRepository? create(Ref ref) {
    return feedbackRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedbackRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedbackRepository?>(value),
    );
  }
}

String _$feedbackRepositoryHash() =>
    r'8589c8dfae7a4ae870ddc72a92effc46baf6aaba';

@ProviderFor(feedbackOutboxStore)
const feedbackOutboxStoreProvider = FeedbackOutboxStoreProvider._();

final class FeedbackOutboxStoreProvider
    extends
        $FunctionalProvider<
          FeedbackOutboxStore,
          FeedbackOutboxStore,
          FeedbackOutboxStore
        >
    with $Provider<FeedbackOutboxStore> {
  const FeedbackOutboxStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedbackOutboxStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedbackOutboxStoreHash();

  @$internal
  @override
  $ProviderElement<FeedbackOutboxStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FeedbackOutboxStore create(Ref ref) {
    return feedbackOutboxStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedbackOutboxStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedbackOutboxStore>(value),
    );
  }
}

String _$feedbackOutboxStoreHash() =>
    r'406f29f629bd667c6c226c7badf69476228c5d93';

@ProviderFor(feedbackContextSource)
const feedbackContextSourceProvider = FeedbackContextSourceProvider._();

final class FeedbackContextSourceProvider
    extends
        $FunctionalProvider<
          FeedbackContextSource,
          FeedbackContextSource,
          FeedbackContextSource
        >
    with $Provider<FeedbackContextSource> {
  const FeedbackContextSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedbackContextSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedbackContextSourceHash();

  @$internal
  @override
  $ProviderElement<FeedbackContextSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FeedbackContextSource create(Ref ref) {
    return feedbackContextSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedbackContextSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedbackContextSource>(value),
    );
  }
}

String _$feedbackContextSourceHash() =>
    r'ad233ccf3f19ed114b7d7ff6895b430cf7f5830e';

/// Whether the signed-in account holds an active tester seat. Answers from
/// the copy remembered on this phone first so the Profile entry does not
/// pop in late, then confirms with the server. A failed check keeps the
/// remembered answer; with none, the answer is no.

@ProviderFor(hasTesterSeat)
const hasTesterSeatProvider = HasTesterSeatProvider._();

/// Whether the signed-in account holds an active tester seat. Answers from
/// the copy remembered on this phone first so the Profile entry does not
/// pop in late, then confirms with the server. A failed check keeps the
/// remembered answer; with none, the answer is no.

final class HasTesterSeatProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Whether the signed-in account holds an active tester seat. Answers from
  /// the copy remembered on this phone first so the Profile entry does not
  /// pop in late, then confirms with the server. A failed check keeps the
  /// remembered answer; with none, the answer is no.
  const HasTesterSeatProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasTesterSeatProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasTesterSeatHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return hasTesterSeat(ref);
  }
}

String _$hasTesterSeatHash() => r'3ccf6a23222705e1f5362c772ab16833ddbfefae';

/// The signed-in tester's own reports, newest first. Sends anything saved
/// while offline before reading, so a report written on the road shows up
/// as soon as there is signal.

@ProviderFor(myFeedback)
const myFeedbackProvider = MyFeedbackProvider._();

/// The signed-in tester's own reports, newest first. Sends anything saved
/// while offline before reading, so a report written on the road shows up
/// as soon as there is signal.

final class MyFeedbackProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FeedbackReport>>,
          List<FeedbackReport>,
          FutureOr<List<FeedbackReport>>
        >
    with
        $FutureModifier<List<FeedbackReport>>,
        $FutureProvider<List<FeedbackReport>> {
  /// The signed-in tester's own reports, newest first. Sends anything saved
  /// while offline before reading, so a report written on the road shows up
  /// as soon as there is signal.
  const MyFeedbackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myFeedbackProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myFeedbackHash();

  @$internal
  @override
  $FutureProviderElement<List<FeedbackReport>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FeedbackReport>> create(Ref ref) {
    return myFeedback(ref);
  }
}

String _$myFeedbackHash() => r'51eb51e16f4d60ead2055f3c8bf1f75651098f27';
