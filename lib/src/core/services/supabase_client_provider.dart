import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_client_provider.g.dart';

/// The app's Supabase client, or null when the build has no Supabase
/// config (no `SUPABASE_URL` / key dart-defines).
///
/// Overridden once at start-up by `buildAppRoot` in
/// `app/app_bootstrap.dart`, so nothing reads `Supabase.instance`
/// directly. Tests override this or the repositories that read it.
@Riverpod(keepAlive: true)
SupabaseClient? supabaseClient(Ref ref) => throw UnimplementedError(
  'supabaseClientProvider is overridden at start-up (buildAppRoot).',
);
