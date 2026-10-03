import 'package:flutter/services.dart';

abstract final class DeviceBatteryReader {
  static const _channel = MethodChannel(
    'com.giglab.kaunti47/location_diagnostics',
  );

  static Future<int> percent() async {
    try {
      final value = await _channel.invokeMethod<int>('batteryPercent');
      return value == null || value < 0 ? -1 : value;
    } on Object {
      return -1;
    }
  }
}
