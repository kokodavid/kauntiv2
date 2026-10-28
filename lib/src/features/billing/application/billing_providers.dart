import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_config_provider.dart';
import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../data/billing_flag_repository.dart';
import '../data/billing_repository.dart';
import '../domain/pro_plan.dart';

part 'billing_providers.g.dart';

/// The dashboard's billing switch. Null without Supabase.
@Riverpod(keepAlive: true)
BillingFlagRepository? billingFlagRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseBillingFlagRepository(client);
}

/// Whether the dashboard has purchases switched on. Read once at start-up;
/// any failure (offline, no config) means off, so no purchase screen shows
/// by accident.
@Riverpod(keepAlive: true)
Future<bool> billingFlag(Ref ref) async {
  final repository = ref.watch(billingFlagRepositoryProvider);
  if (repository == null) return false;
  try {
    return await repository.isEnabled().timeout(const Duration(seconds: 5));
  } on Object {
    return false;
  }
}

/// The store connection for this build, or null when this platform has no
/// RevenueCat key (purchases are then off).
@Riverpod(keepAlive: true)
BillingRepository? billingRepository(Ref ref) {
  final config = ref.watch(appConfigProvider);
  final key = defaultTargetPlatform == TargetPlatform.iOS
      ? config.revenueCatIosKey
      : config.revenueCatAndroidKey;
  return key.isEmpty ? null : RevenueCatBillingRepository(apiKey: key);
}

/// Whether the app may offer Pro purchases right now: the dashboard switch
/// is on, this build has store keys, and someone is signed in (purchases
/// are recorded against the account).
@riverpod
bool billingAvailable(Ref ref) {
  if (ref.watch(billingRepositoryProvider) == null) return false;
  if (ref.watch(authUserIdProvider).value == null) return false;
  return ref.watch(billingFlagProvider).value ?? false;
}

/// The plans to show, annual first. Empty when purchases aren't available.
@riverpod
Future<List<ProPlan>> proPlans(Ref ref) async {
  final repository = ref.watch(billingRepositoryProvider);
  final userId = ref.watch(authUserIdProvider).value;
  if (repository == null || userId == null) return const [];
  await repository.signIn(userId);
  return repository.plans();
}
