// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_collaboration_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The sharing calls. Null when the build has no Supabase.

@ProviderFor(planCollaborationRepository)
const planCollaborationRepositoryProvider =
    PlanCollaborationRepositoryProvider._();

/// The sharing calls. Null when the build has no Supabase.

final class PlanCollaborationRepositoryProvider
    extends
        $FunctionalProvider<
          PlanCollaborationRepository?,
          PlanCollaborationRepository?,
          PlanCollaborationRepository?
        >
    with $Provider<PlanCollaborationRepository?> {
  /// The sharing calls. Null when the build has no Supabase.
  const PlanCollaborationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planCollaborationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planCollaborationRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlanCollaborationRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlanCollaborationRepository? create(Ref ref) {
    return planCollaborationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanCollaborationRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanCollaborationRepository?>(value),
    );
  }
}

String _$planCollaborationRepositoryHash() =>
    r'9bd40af1f5192ab6d38a1f87095e365e44d82abf';

/// What an invite link says before the person joins.

@ProviderFor(invitePreview)
const invitePreviewProvider = InvitePreviewFamily._();

/// What an invite link says before the person joins.

final class InvitePreviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<InvitePreview>,
          InvitePreview,
          FutureOr<InvitePreview>
        >
    with $FutureModifier<InvitePreview>, $FutureProvider<InvitePreview> {
  /// What an invite link says before the person joins.
  const InvitePreviewProvider._({
    required InvitePreviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'invitePreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$invitePreviewHash();

  @override
  String toString() {
    return r'invitePreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<InvitePreview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InvitePreview> create(Ref ref) {
    final argument = this.argument as String;
    return invitePreview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InvitePreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$invitePreviewHash() => r'd794df793d1388feb3cc263d074974f55768a37c';

/// What an invite link says before the person joins.

final class InvitePreviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<InvitePreview>, String> {
  const InvitePreviewFamily._()
    : super(
        retry: null,
        name: r'invitePreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// What an invite link says before the person joins.

  InvitePreviewProvider call(String token) =>
      InvitePreviewProvider._(argument: token, from: this);

  @override
  String toString() => r'invitePreviewProvider';
}

@ProviderFor(planJoiner)
const planJoinerProvider = PlanJoinerProvider._();

final class PlanJoinerProvider
    extends $FunctionalProvider<PlanJoiner, PlanJoiner, PlanJoiner>
    with $Provider<PlanJoiner> {
  const PlanJoinerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planJoinerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planJoinerHash();

  @$internal
  @override
  $ProviderElement<PlanJoiner> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlanJoiner create(Ref ref) {
    return planJoiner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanJoiner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanJoiner>(value),
    );
  }
}

String _$planJoinerHash() => r'f1d3183aff02bd3836ff5a5e478d698e1f45796c';
