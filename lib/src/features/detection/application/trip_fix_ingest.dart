import 'dart:async';

import '../../../services/app_logger.dart';
import '../data/detection_repository.dart';

/// Feeds a recording Trip's location fixes into county detection.
///
/// A Trip already holds a stream of accurate, time-stamped fixes, so a
/// county crossing during one can be placed at the fix's own time instead of
/// whenever the OS next woke the app. Nothing new is requested from the
/// phone: no extra permission, notification or battery cost. Outside a Trip,
/// detection stays on its geofences.
///
/// Fixes are throttled (a polygon lookup every few seconds would be wasted
/// work) and a failure here never reaches the Trip.
class TripFixIngest {
  TripFixIngest(
    this._repository, {
    required bool Function() isSignedIn,
    Duration minGap = const Duration(seconds: 20),
    Duration maxAge = const Duration(minutes: 2),
    DateTime Function()? clock,
  }) : _isSignedIn = isSignedIn,
       _minGap = minGap,
       _maxAge = maxAge,
       _clock = clock ?? DateTime.now;

  final DetectionRepository Function() _repository;
  final bool Function() _isSignedIn;
  final Duration _minGap;
  final Duration _maxAge;
  final DateTime Function() _clock;

  static const _logger = AppLogger.detection();

  DateTime? _lastAt;
  bool _busy = false;

  /// One fix from the Trip. Dropped when signed out, still being handled,
  /// too soon after the last one, or older than [_maxAge] (a cached fix from
  /// before the Trip started says nothing about where the phone is now).
  Future<void> offer({
    required double latitude,
    required double longitude,
    required DateTime at,
  }) async {
    if (_busy || !_isSignedIn()) return;
    if (_clock().difference(at) > _maxAge) return;
    final last = _lastAt;
    if (last != null && at.difference(last).abs() < _minGap) return;
    _busy = true;
    _lastAt = at;
    try {
      await _repository().reconcileCurrentLocation(
        latitude: latitude,
        longitude: longitude,
        now: at,
      );
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Trip fix could not be reconciled.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _busy = false;
    }
  }
}
