import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../../services/app_logger.dart';
import '../../../services/app_supabase.dart';
import '../domain/auth_failure.dart';
import 'auth_failure_mapper.dart';

class AppAuthConfigurationException implements Exception {
  const AppAuthConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppAuthService {
  const AppAuthService({this.client});

  final SupabaseClient? client;
  SupabaseClient get _client => client ?? AppSupabase.client;

  static const _logger = AppLogger.auth();
  static final _googleNonce = generateNonce();
  static Future<void>? _googleInitialization;

  bool get isAvailable => client != null || AppSupabase.isInitialized;

  User? get currentUser => (client != null || AppSupabase.isInitialized)
      ? _client.auth.currentUser
      : null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Signs in with [provider]. Returns null on success, else the failure
  /// to show (already logged).
  Future<AuthFailure?> signIn(AppAuthProvider provider, AppConfig config) async {
    try {
      switch (provider) {
        case AppAuthProvider.google:
          await signInWithGoogle(config);
        case AppAuthProvider.apple:
          await signInWithApple();
      }
      return null;
    } on Object catch (error, stackTrace) {
      return authFailureFor(error, stackTrace);
    }
  }

  Future<void> signInWithGoogle(AppConfig config) async {
    _ensureAvailable();
    if (config.googleWebClientId.isEmpty) {
      throw const AppAuthConfigurationException(
        'Google sign in is unavailable in this build (missing web client ID).',
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        config.googleIosClientId.isEmpty) {
      throw const AppAuthConfigurationException(
        'Google sign in is unavailable in this build (missing iOS client ID).',
      );
    }

    _logger.info('Starting native Google sign in.');
    final rawNonce = _googleNonce;
    final signIn = GoogleSignIn.instance;
    await (_googleInitialization ??= signIn.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? config.googleIosClientId
          : null,
      serverClientId: config.googleWebClientId,
      nonce: _sha256(rawNonce),
    ));

    final googleAccount = await signIn.authenticate();
    final idToken = googleAccount.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('Google sign in did not return an ID token.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      nonce: rawNonce,
    );
    _logger.info('Supabase Google sign in completed.');
  }

  Future<void> signInWithApple() async {
    _ensureAvailable();
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      throw StateError('Native Apple sign in is only available on iOS.');
    }

    _logger.info('Starting native Apple sign in.');
    final rawNonce = generateNonce();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: _sha256(rawNonce),
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Apple sign in did not return an ID token.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
    _logger.info('Supabase Apple sign in completed.');
  }

  Future<void> signOut() async {
    _ensureAvailable();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (error, stackTrace) {
      _logger.debug(
        'Google sign out skipped.',
        error: error,
        stackTrace: stackTrace,
      );
    }
    await _client.auth.signOut();
  }

  void _ensureAvailable() {
    if (!isAvailable) {
      throw const AppAuthConfigurationException(
        'Sign in is unavailable in this build (missing server configuration).',
      );
    }
  }
}

String _sha256(String input) {
  final bytes = utf8.encode(input);
  return sha256.convert(bytes).toString();
}
