import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../data/passport_share_flag_repository.dart';

part 'passport_share_providers.g.dart';

/// The dashboard's Passport share switch. Null without Supabase.
@Riverpod(keepAlive: true)
PassportShareFlagRepository? passportShareFlagRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabasePassportShareFlagRepository(client);
}

/// Whether the dashboard has Passport sharing switched on. A failed read
/// falls back to the last value seen, then to off, so the button never shows
/// by accident and doesn't flicker when the phone is offline. The Passport
/// screen refreshes it when it opens.
@Riverpod(keepAlive: true)
Future<bool> passportShareFlag(Ref ref) async {
  final repository = ref.watch(passportShareFlagRepositoryProvider);
  if (repository == null) return false;
  try {
    return await repository.isEnabled().timeout(const Duration(seconds: 5));
  } on Object {
    return await repository.lastKnown() ?? false;
  }
}
