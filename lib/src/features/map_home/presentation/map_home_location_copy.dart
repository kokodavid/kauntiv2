import 'package:flutter/material.dart';

import '../../detection/domain/detection_status.dart';

/// The words and colours for each way detection can fall short, shared by
/// the launch banner and the pill that follows it. Amber for catch-up
/// ("While using"), red when nothing is being tracked.
class LocationStatusCopy {
  const LocationStatusCopy({
    required this.title,
    required this.body,
    required this.action,
    required this.pillLabel,
    required this.ink,
    required this.accent,
    required this.background,
    required this.border,
  });

  final String title;
  final String body;
  final String action;

  /// The short label on the pill that follows the banner.
  final String pillLabel;
  final Color ink;
  final Color accent;
  final Color background;
  final Color border;

  static const _amber = (
    ink: Color(0xFF7A3E00),
    accent: Color(0xFFB45309),
    background: Color(0xFFFFF7E6),
    border: Color(0xFFF2C26B),
  );
  static const _red = (
    ink: Color(0xFF7F1D1D),
    accent: Color(0xFFB91C1C),
    background: Color(0xFFFEF2F2),
    border: Color(0xFFF5B5B5),
  );

  static LocationStatusCopy of(DetectionReason reason) => switch (reason) {
    DetectionReason.noPermission => LocationStatusCopy(
      title: 'Location is not allowed',
      body: "Kaunti47 can't track counties until you allow location.",
      action: 'Open Settings',
      pillLabel: 'Not tracking',
      ink: _red.ink,
      accent: _red.accent,
      background: _red.background,
      border: _red.border,
    ),
    DetectionReason.servicesOff => LocationStatusCopy(
      title: 'Location is turned off',
      body: "Counties won't update until location is back on.",
      action: 'Turn on',
      pillLabel: 'Not tracking',
      ink: _red.ink,
      accent: _red.accent,
      background: _red.background,
      border: _red.border,
    ),
    DetectionReason.backgroundMissing ||
    DetectionReason.none => LocationStatusCopy(
      title: 'Tracking only while the app is open',
      body: 'Counties you cross with the app closed can be missed.',
      action: 'Allow all the time',
      pillLabel: 'Only tracking while open',
      ink: _amber.ink,
      accent: _amber.accent,
      background: _amber.background,
      border: _amber.border,
    ),
  };
}
