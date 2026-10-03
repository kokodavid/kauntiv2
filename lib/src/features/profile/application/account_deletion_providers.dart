import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../data/account_deletion_repository.dart';

part 'account_deletion_providers.g.dart';

@riverpod
AccountDeletionRepository? accountDeletionRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseAccountDeletionRepository(client);
}
