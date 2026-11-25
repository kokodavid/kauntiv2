import '../domain/journey_device_settings.dart';
import '../domain/journey_pause_reason.dart';

/// Explains a pause without making an automatic pause look like a mistake.
String journeyPausedNote(
  JourneyPauseReason? reason, {
  JourneyDeviceSettings? pauseSettings,
}) => switch (reason) {
  JourneyPauseReason.locationLost =>
    'We lost your location, so the Trip paused.'
        '${_batteryCauseClause(pauseSettings)}'
        " Tap Resume once it is back. The gap isn't drawn.",
  JourneyPauseReason.appRestarted =>
    'The app was closed, so the Trip paused. Tap Resume to carry on. '
        "The time it was closed isn't drawn.",
  JourneyPauseReason.startFailed =>
    "We couldn't get your location, so the Trip paused. Check that "
        'location is on, then tap Resume.',
  JourneyPauseReason.accountChanged =>
    'The account changed, so this Trip paused. Sign back in to resume it.',
  JourneyPauseReason.user || JourneyPauseReason.unknown || null =>
    "Anything between now and Resume isn't drawn, "
        'including time the app was closed.',
};

String _batteryCauseClause(JourneyDeviceSettings? pauseSettings) {
  final warnings = pauseSettings?.warnings ?? const [];
  if (warnings.isEmpty) return '';
  return switch (warnings.first) {
    JourneySettingsWarning.batterySaver =>
      ' Battery saver turned on can cut off location in the background --'
          ' worth checking it is off before you resume.',
    JourneySettingsWarning.lowBattery =>
      ' Your battery ran low, which can trigger power saving that cuts'
          ' off location.',
    JourneySettingsWarning.batteryOptimisation =>
      " This phone's battery settings can pause location in the"
          ' background -- check that battery optimisation for Kaunti47'
          ' is turned off.',
  };
}
