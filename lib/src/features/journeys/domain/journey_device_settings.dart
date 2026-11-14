/// Something about the phone's settings that can cut a Trip's recording
/// short, worth telling the person about before they start.
enum JourneySettingsWarning { batterySaver, lowBattery, batteryOptimisation }

/// What the phone's power settings looked like when a Trip started. Every
/// value can be unknown (null) when the phone would not say.
class JourneyDeviceSettings {
  const JourneyDeviceSettings({
    this.batterySaver,
    this.batteryOptimised,
    this.batteryPercent,
    this.strictMaker = false,
  });

  /// Low Power Mode (iOS) or battery saver (Android) is on.
  final bool? batterySaver;

  /// Android only: the app is subject to battery optimisation (it is not on
  /// the unrestricted list).
  final bool? batteryOptimised;

  final int? batteryPercent;

  /// The phone is from a maker known for stopping background apps harder
  /// than stock Android.
  final bool strictMaker;

  /// Below this the phone is about to turn battery saver on by itself.
  static const lowBatteryPercent = 15;

  /// What to tell the person before the Trip starts. Battery optimisation
  /// only counts on makers known to enforce it hard, since most Android
  /// phones are optimised by default and a warning every time would be noise.
  List<JourneySettingsWarning> get warnings => [
    if (batterySaver == true) JourneySettingsWarning.batterySaver,
    if (batteryPercent != null && batteryPercent! < lowBatteryPercent)
      JourneySettingsWarning.lowBattery,
    if (batteryOptimised == true && strictMaker)
      JourneySettingsWarning.batteryOptimisation,
  ];

  Map<String, Object> toJson() => {
    if (batterySaver != null) 'battery_saver': batterySaver!,
    if (batteryOptimised != null) 'battery_optimised': batteryOptimised!,
    if (batteryPercent != null) 'battery_percent': batteryPercent!,
    'strict_maker': strictMaker,
  };

  /// Reads what [toJson] wrote; null for anything that is not a map.
  static JourneyDeviceSettings? fromJson(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    bool? flag(String key) {
      final value = data[key];
      return value is bool ? value : null;
    }

    final percent = data['battery_percent'];
    return JourneyDeviceSettings(
      batterySaver: flag('battery_saver'),
      batteryOptimised: flag('battery_optimised'),
      batteryPercent: percent is int && percent >= 0 && percent <= 100
          ? percent
          : null,
      strictMaker: flag('strict_maker') ?? false,
    );
  }
}

/// Reads the phone's current power settings.
abstract interface class JourneyDeviceSettingsSource {
  Future<JourneyDeviceSettings> read();
}
