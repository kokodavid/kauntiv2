import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AccountDeletionRepository {
  Future<void> deleteAccount();
}

/// Calls `delete_account()` (see migration
/// `20261003091000_add_delete_account_rpc.sql`). The RPC cascades through
/// every `on delete cascade` FK to auth.users; the caller is responsible
/// for signing out locally afterward since the session's own refresh
/// token is gone the moment the row disappears.
class SupabaseAccountDeletionRepository implements AccountDeletionRepository {
  const SupabaseAccountDeletionRepository(this.client);

  final SupabaseClient client;

  @override
  Future<void> deleteAccount() async {
    await client
        .rpc<void>('delete_account')
        .timeout(const Duration(seconds: 15));
  }
}
