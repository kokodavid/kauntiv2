import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/journey_device_settings.dart';

/// Reads battery saver, battery level and (on Android) battery optimisation
/// from the phone. Each reading is separate and optional: one that fails
/// leaves that value unknown and never stops the others.
class PlatformJourneySettingsSource implements JourneyDeviceSettingsSource {
  PlatformJourneySettingsSource({Battery? battery})
    : _battery = battery ?? Battery();

  final Battery _battery;

  /// Makers whose phones are known to stop background apps harder than
  /// stock Android. Matched on the lower-case manufacturer name.
  static const strictMakers = {
    'xiaomi',
    'redmi',
    'poco',
    'huawei',
    'honor',
    'oppo',
    'realme',
    'oneplus',
    'vivo',
    'samsung',
    'tecno',
    'infinix',
    'itel',
  };

  @override
  Future<JourneyDeviceSettings> read() async {
    bool? saver;
    int? percent;
    bool? optimised;
    var strict = false;
    try {
      saver = await _battery.isInBatterySaveMode;
    } on Object {
      // Unknown on this phone.
    }
    try {
      percent = await _battery.batteryLevel;
    } on Object {
      // Unknown on this phone.
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        optimised = !await Permission.ignoreBatteryOptimizations.isGranted;
      } on Object {
        // Unknown on this phone.
      }
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        strict = strictMakers.contains(info.manufacturer.toLowerCase());
      } on Object {
        // Unknown on this phone.
      }
    }
    return JourneyDeviceSettings(
      batterySaver: saver,
      batteryOptimised: optimised,
      batteryPercent: percent,
      strictMaker: strict,
    );
  }
}
