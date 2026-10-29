// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_sharing.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The live invite links of a plan, for the invite sheet.

@ProviderFor(planInvites)
const planInvitesProvider = PlanInvitesFamily._();

/// The live invite links of a plan, for the invite sheet.

final class PlanInvitesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlanInviteInfo>>,
          List<PlanInviteInfo>,
          FutureOr<List<PlanInviteInfo>>
        >
    with
        $FutureModifier<List<PlanInviteInfo>>,
        $FutureProvider<List<PlanInviteInfo>> {
  /// The live invite links of a plan, for the invite sheet.
  const PlanInvitesProvider._({
    required PlanInvitesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'planInvitesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planInvitesHash();

  @override
  String toString() {
    return r'planInvitesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlanInviteInfo>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlanInviteInfo>> create(Ref ref) {
    final argument = this.argument as String;
    return planInvites(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlanInvitesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planInvitesHash() => r'59d6a4fb7df52fc71f4e85a1195f7a4f5747b5ef';

/// The live invite links of a plan, for the invite sheet.

final class PlanInvitesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PlanInviteInfo>>, String> {
  const PlanInvitesFamily._()
    : super(
        retry: null,
        name: r'planInvitesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The live invite links of a plan, for the invite sheet.

  PlanInvitesProvider call(String planId) =>
      PlanInvitesProvider._(argument: planId, from: this);

  @override
  String toString() => r'planInvitesProvider';
}

/// People matching what was typed (3 letters or more).

@ProviderFor(usernameSearch)
const usernameSearchProvider = UsernameSearchFamily._();

/// People matching what was typed (3 letters or more).

final class UsernameSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UsernameHit>>,
          List<UsernameHit>,
          FutureOr<List<UsernameHit>>
        >
    with
        $FutureModifier<List<UsernameHit>>,
        $FutureProvider<List<UsernameHit>> {
  /// People matching what was typed (3 letters or more).
  const UsernameSearchProvider._({
    required UsernameSearchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'usernameSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$usernameSearchHash();

  @override
  String toString() {
    return r'usernameSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<UsernameHit>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UsernameHit>> create(Ref ref) {
    final argument = this.argument as String;
    return usernameSearch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UsernameSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$usernameSearchHash() => r'c3be520e7bf729642fd064e7ddbb092be0a392bc';

/// People matching what was typed (3 letters or more).

final class UsernameSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<UsernameHit>>, String> {
  const UsernameSearchFamily._()
    : super(
        retry: null,
        name: r'usernameSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// People matching what was typed (3 letters or more).

  UsernameSearchProvider call(String prefix) =>
      UsernameSearchProvider._(argument: prefix, from: this);

  @override
  String toString() => r'usernameSearchProvider';
}

/// Plans people invited me to by username, waiting for my answer.

@ProviderFor(myPlanInvitations)
const myPlanInvitationsProvider = MyPlanInvitationsProvider._();

/// Plans people invited me to by username, waiting for my answer.

final class MyPlanInvitationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlanInvitation>>,
          List<PlanInvitation>,
          FutureOr<List<PlanInvitation>>
        >
    with
        $FutureModifier<List<PlanInvitation>>,
        $FutureProvider<List<PlanInvitation>> {
  /// Plans people invited me to by username, waiting for my answer.
  const MyPlanInvitationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPlanInvitationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPlanInvitationsHash();

  @$internal
  @override
  $FutureProviderElement<List<PlanInvitation>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlanInvitation>> create(Ref ref) {
    return myPlanInvitations(ref);
  }
}

String _$myPlanInvitationsHash() => r'009e16236d83f8fce10eb937952a5a2154206ca4';

@ProviderFor(planSharing)
const planSharingProvider = PlanSharingProvider._();

final class PlanSharingProvider
    extends $FunctionalProvider<PlanSharing, PlanSharing, PlanSharing>
    with $Provider<PlanSharing> {
  const PlanSharingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planSharingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planSharingHash();

  @$internal
  @override
  $ProviderElement<PlanSharing> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlanSharing create(Ref ref) {
    return planSharing(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanSharing value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanSharing>(value),
    );
  }
}

String _$planSharingHash() => r'4ce23ee3e388d6347c5d7cfdf69a08330fd154bf';
