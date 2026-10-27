import '../domain/check_in_outcome.dart';
import 'check_in_messages.dart';

enum CheckInIcon { pin, check, signal, clock, locationOff }

/// What the check-in row shows: an icon, a title, one line under it and the
/// action, if there is one. [tinted] marks a check-in that just counted.
class CheckInView {
  const CheckInView({
    required this.icon,
    required this.title,
    required this.sub,
    this.action,
    this.tinted = false,
    this.busy = false,
  });

  final CheckInIcon icon;
  final String title;
  final String sub;

  /// The pill's label; null when there is nothing to tap.
  final String? action;
  final bool tinted;
  final bool busy;

  /// The row for the current state. [outcome] is the last answer from this
  /// visit to the page; [failed] means the request itself didn't go through.
  factory CheckInView.of({
    required PlaceCheckInStatus status,
    required CheckInOutcome? outcome,
    required String placeName,
    required bool busy,
    required bool failed,
  }) {
    if (busy) {
      return const CheckInView(
        icon: CheckInIcon.pin,
        title: 'Finding you…',
        sub: 'Hold still for a few seconds',
        action: 'Locating',
        busy: true,
      );
    }
    if (failed) {
      return const CheckInView(
        icon: CheckInIcon.pin,
        title: "Couldn't check in",
        sub: checkInErrorShort,
        action: 'Try again',
      );
    }
    if (outcome != null && outcome.counted && !outcome.already) {
      final away = outcome.distanceMeters;
      return CheckInView(
        icon: CheckInIcon.check,
        title: "You're at $placeName",
        sub: away == null
            ? 'Added to your passport'
            : '${checkInLength(away)} away · Added to your passport',
        tinted: true,
      );
    }
    if (status.checkedInToday || (outcome?.counted ?? false)) {
      return const CheckInView(
        icon: CheckInIcon.check,
        title: 'Checked in today',
        sub: 'Come back tomorrow to add another day',
      );
    }
    final failure = outcome?.failure;
    if (failure != null) return _failed(failure, outcome!);
    if (status.visits > 0) {
      final days = status.visits;
      return CheckInView(
        icon: CheckInIcon.check,
        title: 'Checked in on $days ${days == 1 ? 'day' : 'days'}',
        sub: 'Each new day you visit counts toward your passport',
        action: "I'm here",
      );
    }
    return const CheckInView(
      icon: CheckInIcon.pin,
      title: 'Been here?',
      sub: 'Check-ins earn Bronze, Silver and Gold',
      action: "I'm here",
    );
  }

  static CheckInView _failed(CheckInFailure failure, CheckInOutcome outcome) {
    switch (failure) {
      case CheckInFailure.tooFar:
        final d = outcome.distanceMeters;
        final r = outcome.radiusMeters;
        return CheckInView(
          icon: CheckInIcon.pin,
          title: d == null
              ? "You're not here yet"
              : "You're ${checkInLength(d)} away",
          sub: r == null
              ? 'Get closer to the place to check in'
              : 'Get within ${checkInLength(r)} to check in',
          action: 'Try again',
        );
      case CheckInFailure.lowAccuracy:
        return const CheckInView(
          icon: CheckInIcon.signal,
          title: 'Weak GPS signal',
          sub: 'Step into the open and try again',
          action: 'Try again',
        );
      case CheckInFailure.noLocation:
        return const CheckInView(
          icon: CheckInIcon.locationOff,
          title: 'Location is off',
          sub: 'Allow location for Kaunti47 to check in here',
          action: 'Try again',
        );
      case CheckInFailure.dailyLimit:
        return const CheckInView(
          icon: CheckInIcon.clock,
          title: "That's today's limit",
          sub: 'You can check in again tomorrow',
        );
      case CheckInFailure.placeUnavailable:
        return const CheckInView(
          icon: CheckInIcon.pin,
          title: "Can't check in here",
          sub: "This place can't be checked in at right now",
        );
      case CheckInFailure.paused:
        return const CheckInView(
          icon: CheckInIcon.pin,
          title: 'Check-ins are paused',
          sub: 'Try again a little later',
        );
    }
  }
}
