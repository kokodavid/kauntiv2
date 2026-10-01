// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badges_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Badges in the cloud, or null when the build has no Supabase.

@ProviderFor(badgesRepository)
const badgesRepositoryProvider = BadgesRepositoryProvider._();

/// Badges in the cloud, or null when the build has no Supabase.

final class BadgesRepositoryProvider
    extends
        $FunctionalProvider<
          SupabaseBadgesRepository?,
          SupabaseBadgesRepository?,
          SupabaseBadgesRepository?
        >
    with $Provider<SupabaseBadgesRepository?> {
  /// Badges in the cloud, or null when the build has no Supabase.
  const BadgesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'badgesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$badgesRepositoryHash();

  @$internal
  @override
  $ProviderElement<SupabaseBadgesRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupabaseBadgesRepository? create(Ref ref) {
    return badgesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseBadgesRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseBadgesRepository?>(value),
    );
  }
}

String _$badgesRepositoryHash() => r'119b3176cbbc04974f1cc8b30d6207eb0322786f';

/// The signed-in user's badge collection. Reloads when the account
/// changes and when a visit syncs (a new badge or depth).

@ProviderFor(badgeCollection)
const badgeCollectionProvider = BadgeCollectionProvider._();

/// The signed-in user's badge collection. Reloads when the account
/// changes and when a visit syncs (a new badge or depth).

final class BadgeCollectionProvider
    extends
        $FunctionalProvider<
          AsyncValue<BadgeCollection>,
          BadgeCollection,
          FutureOr<BadgeCollection>
        >
    with $FutureModifier<BadgeCollection>, $FutureProvider<BadgeCollection> {
  /// The signed-in user's badge collection. Reloads when the account
  /// changes and when a visit syncs (a new badge or depth).
  const BadgeCollectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'badgeCollectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$badgeCollectionHash();

  @$internal
  @override
  $FutureProviderElement<BadgeCollection> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BadgeCollection> create(Ref ref) {
    return badgeCollection(ref);
  }
}

String _$badgeCollectionHash() => r'fe56e58bb3d3bcdc5b2dada2c8d7e1a71adc39e4';

/// One county's badge in detail, for the badge sheet. Reloads with the
/// collection (account change, visit sync).

@ProviderFor(countyBadgeDetail)
const countyBadgeDetailProvider = CountyBadgeDetailFamily._();

/// One county's badge in detail, for the badge sheet. Reloads with the
/// collection (account change, visit sync).

final class CountyBadgeDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<CountyBadgeDetail>,
          CountyBadgeDetail,
          FutureOr<CountyBadgeDetail>
        >
    with
        $FutureModifier<CountyBadgeDetail>,
        $FutureProvider<CountyBadgeDetail> {
  /// One county's badge in detail, for the badge sheet. Reloads with the
  /// collection (account change, visit sync).
  const CountyBadgeDetailProvider._({
    required CountyBadgeDetailFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'countyBadgeDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$countyBadgeDetailHash();

  @override
  String toString() {
    return r'countyBadgeDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CountyBadgeDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CountyBadgeDetail> create(Ref ref) {
    final argument = this.argument as int;
    return countyBadgeDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CountyBadgeDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$countyBadgeDetailHash() => r'02e4abe9dff7e955b08c7a6f22376094b341d484';

/// One county's badge in detail, for the badge sheet. Reloads with the
/// collection (account change, visit sync).

final class CountyBadgeDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CountyBadgeDetail>, int> {
  const CountyBadgeDetailFamily._()
    : super(
        retry: null,
        name: r'countyBadgeDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One county's badge in detail, for the badge sheet. Reloads with the
  /// collection (account change, visit sync).

  CountyBadgeDetailProvider call(int countyCode) =>
      CountyBadgeDetailProvider._(argument: countyCode, from: this);

  @override
  String toString() => r'countyBadgeDetailProvider';
}

/// Where the user is now, for "Places to start with" distances; null
/// without permission or a fix. A one-shot foreground read, never stored.

@ProviderFor(badgeUserLocation)
const badgeUserLocationProvider = BadgeUserLocationProvider._();

/// Where the user is now, for "Places to start with" distances; null
/// without permission or a fix. A one-shot foreground read, never stored.

final class BadgeUserLocationProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppLocationFix?>,
          AppLocationFix?,
          FutureOr<AppLocationFix?>
        >
    with $FutureModifier<AppLocationFix?>, $FutureProvider<AppLocationFix?> {
  /// Where the user is now, for "Places to start with" distances; null
  /// without permission or a fix. A one-shot foreground read, never stored.
  const BadgeUserLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'badgeUserLocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$badgeUserLocationHash();

  @$internal
  @override
  $FutureProviderElement<AppLocationFix?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppLocationFix?> create(Ref ref) {
    return badgeUserLocation(ref);
  }
}

String _$badgeUserLocationHash() => r'89d3716e4b34da4add48a6d859a32c292e5460de';

@ProviderFor(badgeSpinHistory)
const badgeSpinHistoryProvider = BadgeSpinHistoryProvider._();

final class BadgeSpinHistoryProvider
    extends
        $FunctionalProvider<
          BadgeSpinHistory,
          BadgeSpinHistory,
          BadgeSpinHistory
        >
    with $Provider<BadgeSpinHistory> {
  const BadgeSpinHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'badgeSpinHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$badgeSpinHistoryHash();

  @$internal
  @override
  $ProviderElement<BadgeSpinHistory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BadgeSpinHistory create(Ref ref) {
    return badgeSpinHistory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BadgeSpinHistory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BadgeSpinHistory>(value),
    );
  }
}

String _$badgeSpinHistoryHash() => r'913f307873272776da233d669ed81ce183df3690';

/// Whether this earned badge's coin should spin as its sheet opens: only
/// the first time the account opens it on this phone. Asking records it.
///
/// TEMPORARY while the spin is being tuned: [spinEveryOpen] makes every
/// open spin. Set it back to false before release.

@ProviderFor(badgeFirstSpin)
const badgeFirstSpinProvider = BadgeFirstSpinFamily._();

/// Whether this earned badge's coin should spin as its sheet opens: only
/// the first time the account opens it on this phone. Asking records it.
///
/// TEMPORARY while the spin is being tuned: [spinEveryOpen] makes every
/// open spin. Set it back to false before release.

final class BadgeFirstSpinProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether this earned badge's coin should spin as its sheet opens: only
  /// the first time the account opens it on this phone. Asking records it.
  ///
  /// TEMPORARY while the spin is being tuned: [spinEveryOpen] makes every
  /// open spin. Set it back to false before release.
  const BadgeFirstSpinProvider._({
    required BadgeFirstSpinFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'badgeFirstSpinProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$badgeFirstSpinHash();

  @override
  String toString() {
    return r'badgeFirstSpinProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as int;
    return badgeFirstSpin(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BadgeFirstSpinProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$badgeFirstSpinHash() => r'8657f9d350f5688357e6e8b32cfbbfdd79afd208';

/// Whether this earned badge's coin should spin as its sheet opens: only
/// the first time the account opens it on this phone. Asking records it.
///
/// TEMPORARY while the spin is being tuned: [spinEveryOpen] makes every
/// open spin. Set it back to false before release.

final class BadgeFirstSpinFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, int> {
  const BadgeFirstSpinFamily._()
    : super(
        retry: null,
        name: r'badgeFirstSpinProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether this earned badge's coin should spin as its sheet opens: only
  /// the first time the account opens it on this phone. Asking records it.
  ///
  /// TEMPORARY while the spin is being tuned: [spinEveryOpen] makes every
  /// open spin. Set it back to false before release.

  BadgeFirstSpinProvider call(int countyCode) =>
      BadgeFirstSpinProvider._(argument: countyCode, from: this);

  @override
  String toString() => r'badgeFirstSpinProvider';
}
