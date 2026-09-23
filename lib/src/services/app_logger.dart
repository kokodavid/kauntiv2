import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._(this._scope);

  const AppLogger.auth() : this._('auth');
  const AppLogger.location() : this._('location');
  const AppLogger.mapHome() : this._('map_home');

  final String _scope;

  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _write('DEBUG', message, error: error, stackTrace: stackTrace);
  }

  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _write('INFO', message, error: error, stackTrace: stackTrace);
  }

  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _write('WARN', message, error: error, stackTrace: stackTrace);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _write('ERROR', message, error: error, stackTrace: stackTrace);
  }

  void _write(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[$level] app.$_scope: $message');
    if (error != null) {
      developer.log(
        message,
        name: 'app.$_scope',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint('[$level] app.$_scope error: $error');
    }
  }
}
