import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/trip_alert_notifier.dart';

part 'trip_alert_providers.g.dart';

/// The paused-trip reminder. Tests override it.
@Riverpod(keepAlive: true)
TripAlertNotifier tripAlertNotifier(Ref ref) => TripAlertNotifier();
