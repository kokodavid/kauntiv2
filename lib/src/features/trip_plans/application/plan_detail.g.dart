// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_detail.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A plan by id. Shows the copy on this phone at once, then the server's
/// plan; offline, the copy stays with [PlanDetailView.offline] set. A plan
/// the server no longer knows (deleted, or you were removed) is an error
/// with [PlanFailureKind.notFound] and its copy is dropped.

@ProviderFor(PlanDetail)
const planDetailProvider = PlanDetailFamily._();

/// A plan by id. Shows the copy on this phone at once, then the server's
/// plan; offline, the copy stays with [PlanDetailView.offline] set. A plan
/// the server no longer knows (deleted, or you were removed) is an error
/// with [PlanFailureKind.notFound] and its copy is dropped.
final class PlanDetailProvider
    extends $AsyncNotifierProvider<PlanDetail, PlanDetailView> {
  /// A plan by id. Shows the copy on this phone at once, then the server's
  /// plan; offline, the copy stays with [PlanDetailView.offline] set. A plan
  /// the server no longer knows (deleted, or you were removed) is an error
  /// with [PlanFailureKind.notFound] and its copy is dropped.
  const PlanDetailProvider._({
    required PlanDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'planDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planDetailHash();

  @override
  String toString() {
    return r'planDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlanDetail create() => PlanDetail();

  @override
  bool operator ==(Object other) {
    return other is PlanDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planDetailHash() => r'e592c448e80b229979034510b8c6c4d7ffae3bd1';

/// A plan by id. Shows the copy on this phone at once, then the server's
/// plan; offline, the copy stays with [PlanDetailView.offline] set. A plan
/// the server no longer knows (deleted, or you were removed) is an error
/// with [PlanFailureKind.notFound] and its copy is dropped.

final class PlanDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          PlanDetail,
          AsyncValue<PlanDetailView>,
          PlanDetailView,
          FutureOr<PlanDetailView>,
          String
        > {
  const PlanDetailFamily._()
    : super(
        retry: null,
        name: r'planDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A plan by id. Shows the copy on this phone at once, then the server's
  /// plan; offline, the copy stays with [PlanDetailView.offline] set. A plan
  /// the server no longer knows (deleted, or you were removed) is an error
  /// with [PlanFailureKind.notFound] and its copy is dropped.

  PlanDetailProvider call(String planId) =>
      PlanDetailProvider._(argument: planId, from: this);

  @override
  String toString() => r'planDetailProvider';
}

/// A plan by id. Shows the copy on this phone at once, then the server's
/// plan; offline, the copy stays with [PlanDetailView.offline] set. A plan
/// the server no longer knows (deleted, or you were removed) is an error
/// with [PlanFailureKind.notFound] and its copy is dropped.

abstract class _$PlanDetail extends $AsyncNotifier<PlanDetailView> {
  late final _$args = ref.$arg as String;
  String get planId => _$args;

  FutureOr<PlanDetailView> build(String planId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<PlanDetailView>, PlanDetailView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PlanDetailView>, PlanDetailView>,
              AsyncValue<PlanDetailView>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
