import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../data/profile_setup_repository.dart';

part 'profile_setup_providers.g.dart';

/// The traveller's saved home county. Throws when the build has no
/// Supabase (onboarding only reads it once signed in). Tests override it.
@riverpod
ProfileSetupRepository profileSetupRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase is not configured for this build.');
  }
  return SupabaseProfileSetupRepository(client);
}
