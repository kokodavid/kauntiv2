// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_client_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's Supabase client, or null when the build has no Supabase
/// config (no `SUPABASE_URL` / key dart-defines).
///
/// Overridden once at start-up by `buildAppRoot` in
/// `app/app_bootstrap.dart`, so nothing reads `Supabase.instance`
/// directly. Tests override this or the repositories that read it.

@ProviderFor(supabaseClient)
const supabaseClientProvider = SupabaseClientProvider._();

/// The app's Supabase client, or null when the build has no Supabase
/// config (no `SUPABASE_URL` / key dart-defines).
///
/// Overridden once at start-up by `buildAppRoot` in
/// `app/app_bootstrap.dart`, so nothing reads `Supabase.instance`
/// directly. Tests override this or the repositories that read it.

final class SupabaseClientProvider
    extends
        $FunctionalProvider<SupabaseClient?, SupabaseClient?, SupabaseClient?>
    with $Provider<SupabaseClient?> {
  /// The app's Supabase client, or null when the build has no Supabase
  /// config (no `SUPABASE_URL` / key dart-defines).
  ///
  /// Overridden once at start-up by `buildAppRoot` in
  /// `app/app_bootstrap.dart`, so nothing reads `Supabase.instance`
  /// directly. Tests override this or the repositories that read it.
  const SupabaseClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseClientHash();

  @$internal
  @override
  $ProviderElement<SupabaseClient?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseClient? create(Ref ref) {
    return supabaseClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseClient? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseClient?>(value),
    );
  }
}

String _$supabaseClientHash() => r'42487e366482419ee7eaef899f1a21ee75cbe780';
