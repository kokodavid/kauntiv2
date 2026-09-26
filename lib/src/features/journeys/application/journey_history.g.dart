// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_history.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(JourneyHistoryList)
const journeyHistoryListProvider = JourneyHistoryListProvider._();

final class JourneyHistoryListProvider
    extends $AsyncNotifierProvider<JourneyHistoryList, JourneyHistory> {
  const JourneyHistoryListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyHistoryListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyHistoryListHash();

  @$internal
  @override
  JourneyHistoryList create() => JourneyHistoryList();
}

String _$journeyHistoryListHash() =>
    r'37d44f0ab6a4afc939ebe06987af74b435f79e41';

abstract class _$JourneyHistoryList extends $AsyncNotifier<JourneyHistory> {
  FutureOr<JourneyHistory> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<JourneyHistory>, JourneyHistory>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<JourneyHistory>, JourneyHistory>,
              AsyncValue<JourneyHistory>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
