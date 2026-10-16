import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/place_interest.dart';

/// The traveller's place interests. Picks are written to this phone first
/// and synced to `profiles` after, so setup works offline and an answer
/// given without a connection is sent the next time one is available.
abstract interface class InterestsRepository {
  /// The answer remembered on this phone for the signed-in account, or
  /// null when none exists. Never touches the network.
  Future<InterestsAnswer?> cached();

  /// The saved answer from the server (also remembered on this phone).
  /// Keeps an answer that has not synced yet rather than overwriting it.
  Future<InterestsAnswer?> fetch();

  /// Remember [answer] on this phone, then try to send it. A failed send
  /// is not an error: it is retried by [syncPending].
  Future<void> save(InterestsAnswer answer);

  /// Send an answer that was saved offline. Quiet when there is none.
  Future<void> syncPending();
}

class SupabaseInterestsRepository implements InterestsRepository {
  const SupabaseInterestsRepository(this.client);

  final SupabaseClient client;

  static const _timeout = Duration(seconds: 8);

  String? get _owner => client.auth.currentUser?.id;

  static String _key(String owner) => 'profile.interests.$owner';

  static String _encode(InterestsAnswer a, {required bool pending}) =>
      jsonEncode({
        'interests': [for (final i in a.interests) i.key],
        'completed': a.completed,
        'pending': pending,
      });

  static (InterestsAnswer, bool)? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final keys = (map['interests'] as List).cast<String>();
      return (
        InterestsAnswer(
          interests: PlaceInterest.fromStoredKeys(keys),
          completed: map['completed'] as bool? ?? false,
        ),
        map['pending'] as bool? ?? false,
      );
    } on Object {
      return null;
    }
  }

  Future<(InterestsAnswer, bool)?> _read(String owner) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _decode(prefs.getString(_key(owner)));
    } on Object {
      return null;
    }
  }

  Future<void> _write(
    String owner,
    InterestsAnswer answer, {
    required bool pending,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(owner), _encode(answer, pending: pending));
    } on Object {
      // The copy on this phone is only a speed-up; losing it is harmless.
    }
  }

  @override
  Future<InterestsAnswer?> cached() async {
    final owner = _owner;
    if (owner == null) return null;
    return (await _read(owner))?.$1;
  }

  @override
  Future<InterestsAnswer?> fetch() async {
    final owner = _owner;
    if (owner == null) return null;
    final local = await _read(owner);
    if (local != null && local.$2) return local.$1;
    final row = await client
        .from('profiles')
        .select('interests, preferences_completed')
        .eq('id', owner)
        .maybeSingle()
        .timeout(_timeout);
    if (row == null) return null;
    final answer = InterestsAnswer(
      interests: PlaceInterest.fromStoredKeys(
        ((row['interests'] as List?) ?? const []).cast<String>(),
      ),
      completed: row['preferences_completed'] as bool? ?? false,
    );
    await _write(owner, answer, pending: false);
    return answer;
  }

  Future<void> _send(String owner, InterestsAnswer answer) => client
      .from('profiles')
      .upsert({
        'id': owner,
        'interests': [for (final i in answer.interests) i.key],
        'preferences_completed': answer.completed,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      })
      .timeout(_timeout);

  @override
  Future<void> save(InterestsAnswer answer) async {
    final owner = _owner;
    if (owner == null) return;
    await _write(owner, answer, pending: true);
    try {
      await _send(owner, answer);
      await _write(owner, answer, pending: false);
    } on Object {
      // Offline or slow: stays pending and is sent by syncPending.
    }
  }

  @override
  Future<void> syncPending() async {
    final owner = _owner;
    if (owner == null) return;
    final local = await _read(owner);
    if (local == null || !local.$2) return;
    try {
      await _send(owner, local.$1);
      await _write(owner, local.$1, pending: false);
    } on Object {
      // Try again next time.
    }
  }
}
