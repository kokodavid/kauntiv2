import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../data/interests_repository.dart';

/// The traveller's place interests. Throws when the build has no
/// Supabase (setup only reads it once signed in). Tests override it.
final interestsRepositoryProvider = Provider<InterestsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase is not configured for this build.');
  }
  return SupabaseInterestsRepository(client);
});
