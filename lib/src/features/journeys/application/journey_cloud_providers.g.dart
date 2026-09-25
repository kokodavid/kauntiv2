// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_cloud_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cloud Journeys, or null when the build has no Supabase.

@ProviderFor(supabaseJourneyRepository)
const supabaseJourneyRepositoryProvider = SupabaseJourneyRepositoryProvider._();

/// Cloud Journeys, or null when the build has no Supabase.

final class SupabaseJourneyRepositoryProvider
    extends
        $FunctionalProvider<
          SupabaseJourneyRepository?,
          SupabaseJourneyRepository?,
          SupabaseJourneyRepository?
        >
    with $Provider<SupabaseJourneyRepository?> {
  /// Cloud Journeys, or null when the build has no Supabase.
  const SupabaseJourneyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseJourneyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseJourneyRepositoryHash();

  @$internal
  @override
  $ProviderElement<SupabaseJourneyRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupabaseJourneyRepository? create(Ref ref) {
    return supabaseJourneyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseJourneyRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseJourneyRepository?>(value),
    );
  }
}

String _$supabaseJourneyRepositoryHash() =>
    r'bbbea22cbb209bc235b3aa5662b936df045c742b';

/// Uploads completed Journeys, or null without Supabase.

@ProviderFor(journeyUploadQueue)
const journeyUploadQueueProvider = JourneyUploadQueueProvider._();

/// Uploads completed Journeys, or null without Supabase.

final class JourneyUploadQueueProvider
    extends
        $FunctionalProvider<
          JourneyUploadQueue?,
          JourneyUploadQueue?,
          JourneyUploadQueue?
        >
    with $Provider<JourneyUploadQueue?> {
  /// Uploads completed Journeys, or null without Supabase.
  const JourneyUploadQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyUploadQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyUploadQueueHash();

  @$internal
  @override
  $ProviderElement<JourneyUploadQueue?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JourneyUploadQueue? create(Ref ref) {
    return journeyUploadQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JourneyUploadQueue? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JourneyUploadQueue?>(value),
    );
  }
}

String _$journeyUploadQueueHash() =>
    r'669c4617d9bb171d041095ceeee86bf2ac1866e2';

@ProviderFor(proStatusCache)
const proStatusCacheProvider = ProStatusCacheProvider._();

final class ProStatusCacheProvider
    extends $FunctionalProvider<ProStatusCache, ProStatusCache, ProStatusCache>
    with $Provider<ProStatusCache> {
  const ProStatusCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proStatusCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proStatusCacheHash();

  @$internal
  @override
  $ProviderElement<ProStatusCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProStatusCache create(Ref ref) {
    return proStatusCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProStatusCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProStatusCache>(value),
    );
  }
}

String _$proStatusCacheHash() => r'dbaecd31d041a0d811b1afd102ac7edf78f6d5b0';
