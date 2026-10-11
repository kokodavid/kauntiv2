import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../data/interest_place_types_repository.dart';
import '../data/interests_prompt_store.dart';
import '../data/interests_repository.dart';
import '../domain/interest_place_types.dart';
import '../domain/place_interest.dart';

/// The traveller's place interests. Throws when the build has no
/// Supabase (setup only reads it once signed in). Tests override it.
final interestsRepositoryProvider = Provider<InterestsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase is not configured for this build.');
  }
  return SupabaseInterestsRepository(client);
});

/// The "Tell us what you like" card's local memory. Tests override it.
final interestsPromptStoreProvider = Provider<InterestsPromptStore>(
  (ref) => const SharedPreferencesInterestsPromptStore(),
);

/// How many app sessions reach Home before the card first appears.
const interestsPromptMinSessions = 3;

/// The signed-in user's saved interests (Settings, the editor, and the
/// Home card). Starts from the answer remembered on this phone so it works
/// offline, then quietly refreshes from the server. Never errors: with no
/// answer anywhere it reads as unanswered.
final myInterestsProvider =
    AsyncNotifierProvider<MyInterests, InterestsAnswer>(MyInterests.new);

class MyInterests extends AsyncNotifier<InterestsAnswer> {
  @override
  Future<InterestsAnswer> build() async {
    // A different account (or signing out) starts from scratch.
    ref.watch(authUserIdProvider);
    try {
      final repository = ref.read(interestsRepositoryProvider);
      final cached = await repository.cached();
      if (cached != null) {
        unawaited(_refresh(repository));
        return cached;
      }
      return await repository.fetch() ?? const InterestsAnswer.unanswered();
    } on Object {
      return const InterestsAnswer.unanswered();
    }
  }

  Future<void> _refresh(InterestsRepository repository) async {
    try {
      final latest = await repository.fetch();
      if (latest != null && ref.mounted) state = AsyncData(latest);
    } on Object {
      // Keep the answer from this phone.
    }
  }

  /// Saves [picks] as the answer (an empty list is "none"), and updates
  /// every screen reading it.
  Future<void> save(List<PlaceInterest> picks) async {
    final answer = InterestsAnswer(interests: picks, completed: true);
    await ref.read(interestsRepositoryProvider).save(answer);
    if (ref.mounted) state = AsyncData(answer);
  }
}

/// Counts one more app session when first read, and holds the count for
/// the rest of the run, so Home counts a launch once however often it
/// rebuilds.
final interestsSessionCountProvider = FutureProvider<int>((ref) async {
  final owner = ref.read(currentUserIdProvider)();
  if (owner == null) return 0;
  return ref.read(interestsPromptStoreProvider).recordSession(owner);
});

/// Whether Home shows the "Tell us what you like" card: only for someone
/// who has not answered, has not dismissed it, and has opened the app to
/// Home at least [interestsPromptMinSessions] times. Never in the first
/// session.
final interestsPromptProvider =
    AsyncNotifierProvider<InterestsPrompt, bool>(InterestsPrompt.new);

class InterestsPrompt extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final owner = ref.read(currentUserIdProvider)();
    if (owner == null) return false;
    final sessions = await ref.watch(interestsSessionCountProvider.future);
    final answer = await ref.watch(myInterestsProvider.future);
    if (answer.completed || sessions < interestsPromptMinSessions) {
      return false;
    }
    return !await ref.read(interestsPromptStoreProvider).isDismissed(owner);
  }

  /// Hides the card for good (Dismiss, or after saving picks).
  Future<void> dismiss() async {
    final owner = ref.read(currentUserIdProvider)();
    if (owner != null) {
      await ref.read(interestsPromptStoreProvider).dismiss(owner);
    }
    if (ref.mounted) state = const AsyncData(false);
  }
}

/// Which place types count toward each interest, from the backend table so
/// it can change without an app release. Reads as the bundled mapping while
/// loading, offline, or when the table is empty or missing.
final interestPlaceTypesProvider = FutureProvider<InterestPlaceTypes>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return InterestPlaceTypes.fallback;
  try {
    final loaded = await InterestPlaceTypesRepository(client).fetch();
    return loaded.isEmpty ? InterestPlaceTypes.fallback : loaded;
  } on Object {
    return InterestPlaceTypes.fallback;
  }
});
