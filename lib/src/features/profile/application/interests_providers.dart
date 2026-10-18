import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../data/interest_catalogue_repository.dart';
import '../data/interest_place_types_repository.dart';
import '../data/interests_prompt_store.dart';
import '../data/interests_repository.dart';
import '../domain/interest_matcher.dart';
import '../domain/interest_place_types.dart';
import '../domain/place_interest.dart';

part 'interests_providers.g.dart';

/// The traveller's place interests. Throws when the build has no
/// Supabase (setup only reads it once signed in). Tests override it.
@Riverpod(keepAlive: true)
InterestsRepository interestsRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase is not configured for this build.');
  }
  return SupabaseInterestsRepository(client);
}

/// The "Tell us what you like" card's local memory. Tests override it.
@Riverpod(keepAlive: true)
InterestsPromptStore interestsPromptStore(Ref ref) =>
    const SharedPreferencesInterestsPromptStore();

/// How many app sessions reach Home before the card first appears.
const interestsPromptMinSessions = 3;

/// The signed-in user's saved interests (Settings, the editor, and the
/// Home card). Starts from the answer remembered on this phone so it works
/// offline, then quietly refreshes from the server. Never errors: with no
/// answer anywhere it reads as unanswered.
@Riverpod(keepAlive: true)
class MyInterests extends _$MyInterests {
  @override
  Future<InterestsAnswer> build() async {
    // A different account (or signing out) starts from scratch.
    ref.watch(authUserIdProvider);
    // Picks are shown against the live list: an interest an admin switched
    // off disappears, a renamed one shows its new name.
    final catalogue = await ref.watch(interestCatalogueProvider.future);
    try {
      final repository = ref.read(interestsRepositoryProvider);
      final cached = await repository.cached();
      if (cached != null) {
        unawaited(_refresh(repository, catalogue));
        return _resolve(cached, catalogue);
      }
      final fetched = await repository.fetch();
      return fetched == null
          ? const InterestsAnswer.unanswered()
          : _resolve(fetched, catalogue);
    } on Object {
      return const InterestsAnswer.unanswered();
    }
  }

  static InterestsAnswer _resolve(
    InterestsAnswer answer,
    List<PlaceInterest> catalogue,
  ) => answer.copyWith(
    interests: PlaceInterest.fromKeys([
      for (final i in answer.interests) i.key,
    ], catalogue: catalogue),
  );

  Future<void> _refresh(
    InterestsRepository repository,
    List<PlaceInterest> catalogue,
  ) async {
    try {
      final latest = await repository.fetch();
      if (latest != null && ref.mounted) {
        state = AsyncData(_resolve(latest, catalogue));
      }
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
@Riverpod(keepAlive: true)
Future<int> interestsSessionCount(Ref ref) async {
  final owner = ref.read(currentUserIdProvider)();
  if (owner == null) return 0;
  return ref.read(interestsPromptStoreProvider).recordSession(owner);
}

/// Whether Home shows the "Tell us what you like" card: only for someone
/// who has not answered, has not dismissed it, and has opened the app to
/// Home at least [interestsPromptMinSessions] times. Never in the first
/// session.
@Riverpod(keepAlive: true)
class InterestsPrompt extends _$InterestsPrompt {
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
@Riverpod(keepAlive: true)
Future<InterestPlaceTypes> interestPlaceTypes(Ref ref) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return InterestPlaceTypes.fallback;
  try {
    final loaded = await InterestPlaceTypesRepository(client).fetch();
    return loaded.isEmpty ? InterestPlaceTypes.fallback : loaded;
  } on Object {
    return InterestPlaceTypes.fallback;
  }
}

/// The interests a traveller can pick from, ordered by the backend's
/// `sort_order`. Starts at once from the list remembered on this phone (or
/// the built-in set), then swaps in the server's active list when it
/// arrives. Never errors and never empty.
@Riverpod(keepAlive: true)
class InterestCatalogue extends _$InterestCatalogue {
  @override
  Future<List<PlaceInterest>> build() async {
    final client = ref.watch(supabaseClientProvider);
    if (client == null) return PlaceInterest.values;
    final repository = InterestCatalogueRepository(client);
    final cached = await repository.cached();
    unawaited(_refresh(repository));
    return cached.isEmpty ? PlaceInterest.values : cached;
  }

  Future<void> _refresh(InterestCatalogueRepository repository) async {
    try {
      final loaded = await repository.fetch();
      if (loaded.isNotEmpty && ref.mounted) state = AsyncData(loaded);
    } on Object {
      // Offline, or the interests migration has not run: keep what we have.
    }
  }
}

/// Codes of the coastal counties; empty set reads as "not known".
@Riverpod(keepAlive: true)
Future<Set<int>> coastalCountyCodes(Ref ref) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const {};
  try {
    return await InterestCatalogueRepository(client).coastalCountyCodes();
  } on Object {
    return const {};
  }
}

/// Type and county rules for matching a place to an interest, from the
/// backend. Reads as the bundled rules until they load.
@Riverpod(keepAlive: true)
InterestMatcher interestMatcher(Ref ref) {
  final types =
      ref.watch(interestPlaceTypesProvider).value ??
      InterestPlaceTypes.fallback;
  final coastal = ref.watch(coastalCountyCodesProvider).value;
  return InterestMatcher(
    types,
    (coastal == null || coastal.isEmpty)
        ? CountyCoast.unknown
        : CountyCoast(coastal),
  );
}
