import 'dart:async';
import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../data/username_repository.dart';
import '../domain/public_profile.dart';
import '../domain/username.dart';
import '../domain/username_chooser_state.dart';
import 'public_profile_providers.dart';

part 'username_providers.g.dart';

/// The username RPCs, or null when the build has no Supabase.
@riverpod
UsernameRepository? usernameRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseUsernameRepository(client);
}

/// The username chooser behind setup step 3 and Edit Profile: four
/// suggestions to pick from, "Show me more", or the user's own text checked
/// against the server as they type.
@riverpod
class UsernameChooser extends _$UsernameChooser {
  static const _debounce = Duration(milliseconds: 400);
  Timer? _timer;

  @override
  UsernameChooserState build() {
    ref.onDispose(() => _timer?.cancel());
    unawaited(Future.microtask(loadSuggestions));
    return const UsernameChooserState();
  }

  /// Four fresh suggestions ("Show me more" calls this again).
  Future<void> loadSuggestions() async {
    final repository = ref.read(usernameRepositoryProvider);
    if (repository == null) {
      state = state.copyWith(isLoading: false, loadFailed: true);
      return;
    }
    state = state.copyWith(isLoading: true, loadFailed: false);
    try {
      final suggestions = await repository.suggest();
      if (!ref.mounted) return;
      // Once the user has picked or typed something, new suggestions must
      // not replace it; before that, the first one is pre-selected.
      state = state.copyWith(
        suggestions: suggestions,
        isLoading: false,
        isCustom: state.userPicked ? state.isCustom : false,
        selected: state.userPicked
            ? null
            : () => suggestions.isEmpty ? null : suggestions.first,
        error: () => null,
      );
    } on Object catch (error, stack) {
      developer.log(
        'suggest_usernames failed',
        name: 'username',
        error: error,
        stackTrace: stack,
      );
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, loadFailed: true);
    }
  }

  void select(String handle) => state = state.copyWith(
    isCustom: false,
    selected: () => handle,
    userPicked: true,
    error: () => null,
  );

  /// "Edit selected name": the field opens holding the picked suggestion
  /// (the screen puts the text in its controller), or empty if none is
  /// picked. A suggestion is free as far as the server said a moment ago;
  /// editing re-checks it.
  void editSelected() {
    final handle = state.selected;
    state = state.copyWith(
      isCustom: true,
      userPicked: true,
      customText: handle ?? '',
      customCheck: () => handle == null ? null : UsernameCheck.available,
      isChecking: false,
      error: () => null,
    );
  }

  /// Called on every keystroke; the server is asked once typing pauses.
  void onCustomChanged(String text) {
    _timer?.cancel();
    final normalized = normalizeUsername(text);
    state = state.copyWith(
      isCustom: true,
      userPicked: true,
      customText: text,
      customCheck: () => null,
      error: () => null,
      isChecking: false,
    );
    if (normalized.isEmpty) return;
    if (!isValidHandle(normalized)) {
      state = state.copyWith(customCheck: () => UsernameCheck.invalid);
      return;
    }
    state = state.copyWith(isChecking: true);
    _timer = Timer(_debounce, () => unawaited(_check(normalized)));
  }

  Future<void> _check(String handle) async {
    final repository = ref.read(usernameRepositoryProvider);
    if (repository == null) return;
    try {
      final result = await repository.check(handle);
      if (!ref.mounted || normalizeUsername(state.customText) != handle) {
        return;
      }
      state = state.copyWith(customCheck: () => result, isChecking: false);
    } on Object catch (error, stack) {
      developer.log(
        'check_username failed',
        name: 'username',
        error: error,
        stackTrace: stack,
      );
      if (!ref.mounted || normalizeUsername(state.customText) != handle) {
        return;
      }
      state = state.copyWith(
        isChecking: false,
        error: () => "Couldn't check that name. Try again.",
      );
    }
  }

  /// Saves the chosen username. True when it is saved.
  Future<bool> save() async {
    final handle = state.chosen;
    final repository = ref.read(usernameRepositoryProvider);
    if (handle == null || repository == null || state.isSaving) return false;
    state = state.copyWith(isSaving: true, error: () => null);
    try {
      await repository.set(handle);
      ref.invalidate(myPublicProfileProvider);
      return true;
    } on UsernameRateLimitedException catch (error) {
      if (ref.mounted) {
        state = state.copyWith(error: () => _rateLimitedMessage(error));
      }
    } on UsernameRejectedException catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          customCheck: () => error.reason,
          error: () => error.reason.problemMessage,
        );
      }
    } on Object {
      if (ref.mounted) {
        state = state.copyWith(error: () => "Couldn't save. Try again.");
      }
    } finally {
      if (ref.mounted) state = state.copyWith(isSaving: false);
    }
    return false;
  }

  static String _rateLimitedMessage(UsernameRateLimitedException error) {
    final at = error.canChangeAgainAt;
    if (at == null) return 'You can change your username once every 30 days.';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'You can change your username again on '
        '${at.day} ${months[at.month - 1]}.';
  }
}
