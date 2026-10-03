import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../data/public_profile_repository.dart';
import '../domain/public_profile.dart';

part 'public_profile_providers.g.dart';

/// The account's public identity in the cloud, or null when the build has
/// no Supabase.
@riverpod
PublicProfileRepository? publicProfileRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabasePublicProfileRepository(client);
}

/// The signed-in account's display name, handle and avatar. Reloads when
/// the account changes; Edit Profile invalidates this after a successful
/// save or avatar upload.
@riverpod
Future<PublicProfile?> myPublicProfile(Ref ref) async {
  ref.watch(authUserIdProvider);
  final userId = ref.watch(currentUserIdProvider)();
  final repository = ref.watch(publicProfileRepositoryProvider);
  if (userId == null || repository == null) return null;
  return repository.fetch();
}
