import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../../services/app_logger.dart';
import '../data/app_auth_service.dart';
import '../domain/auth_failure.dart';

class SignInController extends ChangeNotifier {
  SignInController(this.authService, this.config);

  final AppAuthService authService;
  final AppConfig config;

  static const _logger = AppLogger.auth();
  AppAuthProvider? providerInProgress;
  AuthFailure? failure;
  String? get errorMessage => failure?.message;
  bool _disposed = false;

  void _update(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> signIn(AppAuthProvider provider) async {
    if (_disposed || providerInProgress != null) return;
    _update(() {
      providerInProgress = provider;
      failure = null;
    });

    try {
      switch (provider) {
        case AppAuthProvider.google:
          await authService.signInWithGoogle(config);
        case AppAuthProvider.apple:
          await authService.signInWithApple();
      }
    } on GoogleSignInException catch (error, stackTrace) {
      _logger.warning(
        'Google sign in failed with ${error.code.name}.',
        error: error,
        stackTrace: stackTrace,
      );
      _update(() {
        final message = switch (error.code) {
          GoogleSignInExceptionCode.canceled => 'Sign in was cancelled.',
          GoogleSignInExceptionCode.clientConfigurationError ||
          GoogleSignInExceptionCode.providerConfigurationError =>
            'Google sign in is not configured correctly yet.',
          GoogleSignInExceptionCode.uiUnavailable =>
            'Google sign in is not available on this device.',
          _ => 'Google sign in failed. Try again.',
        };
        failure = AuthFailure(switch (error.code) {
          GoogleSignInExceptionCode.canceled => AuthFailureKind.cancelled,
          GoogleSignInExceptionCode.clientConfigurationError ||
          GoogleSignInExceptionCode.providerConfigurationError =>
            AuthFailureKind.configuration,
          GoogleSignInExceptionCode.uiUnavailable =>
            AuthFailureKind.unavailable,
          _ => AuthFailureKind.unexpected,
        }, message);
      });
    } on SignInWithAppleAuthorizationException catch (error, stackTrace) {
      _logger.warning(
        'Apple sign in failed with ${error.code.name}.',
        error: error,
        stackTrace: stackTrace,
      );
      _update(() {
        final message = switch (error.code) {
          AuthorizationErrorCode.canceled => 'Sign in was cancelled.',
          AuthorizationErrorCode.notHandled ||
          AuthorizationErrorCode.notInteractive =>
            'Apple sign in is not available right now.',
          AuthorizationErrorCode.invalidResponse ||
          AuthorizationErrorCode.failed => 'Apple sign in failed. Try again.',
          _ => 'Apple sign in failed. Please try again.',
        };
        failure = AuthFailure(
          error.code == AuthorizationErrorCode.canceled
              ? AuthFailureKind.cancelled
              : AuthFailureKind.rejected,
          message,
        );
      });
    } on SignInWithAppleNotSupportedException catch (error, stackTrace) {
      _logger.warning(
        'Apple sign in is not supported on this device.',
        error: error,
        stackTrace: stackTrace,
      );
      _update(() {
        failure = const AuthFailure(
          AuthFailureKind.unavailable,
          'Apple sign in is not supported on this device.',
        );
      });
    } on SignInWithAppleCredentialsException catch (error, stackTrace) {
      _logger.warning(
        'Apple sign in returned invalid credentials.',
        error: error,
        stackTrace: stackTrace,
      );
      _update(() {
        failure = const AuthFailure(
          AuthFailureKind.invalidCredentials,
          'Apple sign in did not return valid credentials.',
        );
      });
    } on AppAuthConfigurationException catch (error, stackTrace) {
      _logger.warning(
        'Sign in build configuration is incomplete.',
        error: error,
        stackTrace: stackTrace,
      );
      _update(() {
        failure = AuthFailure(AuthFailureKind.configuration, error.message);
      });
    } on AuthException catch (error, stackTrace) {
      _logger.warning(
        'Supabase auth rejected sign in.',
        error: error,
        stackTrace: stackTrace,
      );
      _update(() {
        failure = const AuthFailure(
          AuthFailureKind.rejected,
          'Supabase could not complete sign in. Try again.',
        );
      });
    } catch (error, stackTrace) {
      _logger.error(
        'Sign in failed unexpectedly.',
        error: error,
        stackTrace: stackTrace,
      );
      _update(() {
        failure = const AuthFailure(
          AuthFailureKind.unexpected,
          'Sign in failed. Please try again.',
        );
      });
    } finally {
      if (!_disposed) {
        _update(() => providerInProgress = null);
      }
    }
  }
}
