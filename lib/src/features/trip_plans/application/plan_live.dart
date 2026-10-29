import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../data/plan_live_source.dart';
import 'plan_detail.dart';

part 'plan_live.g.dart';

@riverpod
PlanLiveSource? planLiveSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabasePlanLiveSource(client);
}

/// How long to wait after the last change before reading the plan again
/// (a burst of edits is one read).
const planLiveDebounce = Duration(milliseconds: 700);

/// When Realtime is silent or down, the open plan is still read this often.
/// Null (tests) turns the fallback off.
@riverpod
Duration? planLivePollInterval(Ref ref) => const Duration(seconds: 45);

/// Keeps an open plan current: reads it again after a change someone else
/// made, and on a slow timer as a fallback. Watch it from the plan screen;
/// it stops when the screen closes.
@riverpod
void planLive(Ref ref, String planId) {
  Timer? debounce;
  void refresh() {
    if (!ref.mounted) return;
    unawaited(ref.read(planDetailProvider(planId).notifier).refresh());
  }

  PlanLiveSource? source;
  try {
    source = ref.watch(planLiveSourceProvider);
  } on Object {
    source = null; // no Supabase in this build
  }
  final subscription = source?.changes(planId).listen((_) {
    debounce?.cancel();
    debounce = Timer(planLiveDebounce, refresh);
  }, onError: (Object _) {});
  final interval = ref.watch(planLivePollIntervalProvider);
  final poll = interval == null
      ? null
      : Timer.periodic(interval, (_) => refresh());

  ref.onDispose(() {
    debounce?.cancel();
    poll?.cancel();
    unawaited(subscription?.cancel());
  });
}
