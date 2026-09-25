import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../data/app_auth_service.dart';

part 'auth_providers.g.dart';

/// Google / Apple sign-in against the app's Supabase project.
@Riverpod(keepAlive: true)
AppAuthService authService(Ref ref) =>
    AppAuthService(client: ref.watch(supabaseClientProvider));

/// Reads the signed-in user's id at call time (null when signed out or
/// when the build has no Supabase). A function, not a value, because the
/// session changes after sign-in without the provider rebuilding. Tests
/// override it.
@Riverpod(keepAlive: true)
String? Function() currentUserId(Ref ref) {
  final auth = ref.watch(authServiceProvider);
  return () => auth.currentUser?.id;
}
