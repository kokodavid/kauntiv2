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
/// directly. The null default keeps offline and test widget trees usable
/// before startup wiring has supplied a client.

@ProviderFor(supabaseClient)
const supabaseClientProvider = SupabaseClientProvider._();

/// The app's Supabase client, or null when the build has no Supabase
/// config (no `SUPABASE_URL` / key dart-defines).
///
/// Overridden once at start-up by `buildAppRoot` in
/// `app/app_bootstrap.dart`, so nothing reads `Supabase.instance`
/// directly. The null default keeps offline and test widget trees usable
/// before startup wiring has supplied a client.

final class SupabaseClientProvider
    extends
        $FunctionalProvider<SupabaseClient?, SupabaseClient?, SupabaseClient?>
    with $Provider<SupabaseClient?> {
  /// The app's Supabase client, or null when the build has no Supabase
  /// config (no `SUPABASE_URL` / key dart-defines).
  ///
  /// Overridden once at start-up by `buildAppRoot` in
  /// `app/app_bootstrap.dart`, so nothing reads `Supabase.instance`
  /// directly. The null default keeps offline and test widget trees usable
  /// before startup wiring has supplied a client.
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

String _$supabaseClientHash() => r'e034314418ad8d758342b69de8cf5438dfb7b7e1';
