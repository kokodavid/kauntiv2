import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_client_provider.g.dart';

/// The app's Supabase client, or null when the build has no Supabase
/// config (no `SUPABASE_URL` / key dart-defines).
///
/// Overridden once at start-up by `buildAppRoot` in
/// `app/app_bootstrap.dart`, so nothing reads `Supabase.instance`
/// directly. The null default keeps offline and test widget trees usable
/// before startup wiring has supplied a client.
@Riverpod(keepAlive: true)
SupabaseClient? supabaseClient(Ref ref) => null;
