import 'dart:io' show Platform;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/push_destination.dart';

/// The server side of push for this phone: which token belongs to the
/// signed-in user, and which notifications they opened.
abstract interface class PushDeviceRepository {
  Future<void> register({
    required String token,
    required PushPermission permission,
    required String flavor,
    String? appVersion,
  });

  Future<void> remove(String token);

  Future<void> logOpen(String eventId);
}

class SupabasePushDeviceRepository implements PushDeviceRepository {
  const SupabasePushDeviceRepository(this.client);

  final SupabaseClient client;

  static const _timeout = Duration(seconds: 8);

  @override
  Future<void> register({
    required String token,
    required PushPermission permission,
    required String flavor,
    String? appVersion,
  }) async {
    await client
        .rpc<dynamic>(
          'register_push_device',
          params: {
            'p_token': token,
            'p_platform': Platform.isIOS ? 'ios' : 'android',
            'p_flavor': flavor,
            'p_app_version': appVersion,
            'p_os_permission': switch (permission) {
              PushPermission.granted => 'granted',
              PushPermission.denied => 'denied',
              PushPermission.unknown => 'unknown',
            },
          },
        )
        .timeout(_timeout);
  }

  @override
  Future<void> remove(String token) async {
    await client
        .rpc<dynamic>('remove_push_device', params: {'p_token': token})
        .timeout(_timeout);
  }

  @override
  Future<void> logOpen(String eventId) async {
    await client
        .rpc<dynamic>('log_push_open', params: {'p_event_id': eventId})
        .timeout(_timeout);
  }
}
