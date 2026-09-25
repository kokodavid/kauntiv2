import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/app_logger.dart';
import '../domain/auth_failure.dart';
import 'app_auth_service.dart';

const _logger = AppLogger.auth();

/// Turns a sign-in error from Google, Apple or Supabase into the message
/// the sign-in page shows, and logs it.
AuthFailure authFailureFor(Object error, StackTrace stackTrace) {
  switch (error) {
    case GoogleSignInException(:final code):
      _logger.warning(
        'Google sign in failed with ${code.name}.',
        error: error,
        stackTrace: stackTrace,
      );
      return switch (code) {
        GoogleSignInExceptionCode.canceled => const AuthFailure(
          AuthFailureKind.cancelled,
          'Sign in was cancelled.',
        ),
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          const AuthFailure(
            AuthFailureKind.configuration,
            'Google sign in is not configured correctly yet.',
          ),
        GoogleSignInExceptionCode.uiUnavailable => const AuthFailure(
          AuthFailureKind.unavailable,
          'Google sign in is not available on this device.',
        ),
        _ => const AuthFailure(
          AuthFailureKind.unexpected,
          'Google sign in failed. Try again.',
        ),
      };
    case SignInWithAppleAuthorizationException(:final code):
      _logger.warning(
        'Apple sign in failed with ${code.name}.',
        error: error,
        stackTrace: stackTrace,
      );
      final message = switch (code) {
        AuthorizationErrorCode.canceled => 'Sign in was cancelled.',
        AuthorizationErrorCode.notHandled ||
        AuthorizationErrorCode.notInteractive =>
          'Apple sign in is not available right now.',
        AuthorizationErrorCode.invalidResponse ||
        AuthorizationErrorCode.failed => 'Apple sign in failed. Try again.',
        _ => 'Apple sign in failed. Please try again.',
      };
      return AuthFailure(
        code == AuthorizationErrorCode.canceled
            ? AuthFailureKind.cancelled
            : AuthFailureKind.rejected,
        message,
      );
    case SignInWithAppleNotSupportedException():
      _logger.warning(
        'Apple sign in is not supported on this device.',
        error: error,
        stackTrace: stackTrace,
      );
      return const AuthFailure(
        AuthFailureKind.unavailable,
        'Apple sign in is not supported on this device.',
      );
    case SignInWithAppleCredentialsException():
      _logger.warning(
        'Apple sign in returned invalid credentials.',
        error: error,
        stackTrace: stackTrace,
      );
      return const AuthFailure(
        AuthFailureKind.invalidCredentials,
        'Apple sign in did not return valid credentials.',
      );
    case AppAuthConfigurationException(:final message):
      _logger.warning(
        'Sign in build configuration is incomplete.',
        error: error,
        stackTrace: stackTrace,
      );
      return AuthFailure(AuthFailureKind.configuration, message);
    case AuthException():
      _logger.warning(
        'Supabase auth rejected sign in.',
        error: error,
        stackTrace: stackTrace,
      );
      return const AuthFailure(
        AuthFailureKind.rejected,
        'Supabase could not complete sign in. Try again.',
      );
    default:
      _logger.error(
        'Sign in failed unexpectedly.',
        error: error,
        stackTrace: stackTrace,
      );
      return const AuthFailure(
        AuthFailureKind.unexpected,
        'Sign in failed. Please try again.',
      );
  }
}
