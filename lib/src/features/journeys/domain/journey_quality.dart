import 'dart:convert';

import 'journey_device_settings.dart';
import 'journey_pause_reason.dart';

/// How well one Trip recorded, as plain counts: no places, no coordinates.
/// Kept on the phone while the Trip records, then sent with the Trip so the
/// team can see which phones and settings cause gaps and pauses.
class JourneyQuality {
  const JourneyQuality({
    this.pausesByReason = const {},
    this.gaps = 0,
    this.gapMillis = 0,
    this.fixesAccepted = 0,
    this.spikesDropped = 0,
    this.jumpsAccepted = 0,
    this.streamLosses = 0,
    this.streamRecoveries = 0,
    this.lostMillis = 0,
    this.settings,
    this.settingsAtPause,
  });

  /// Pauses by [JourneyPauseReason.storageValue].
  final Map<String, int> pausesByReason;

  /// Stretches with no location fixes that started a new route segment, and
  /// their total length.
  final int gaps;
  final int gapMillis;

  final int fixesAccepted;
  final int spikesDropped;

  /// Far jumps accepted after a second fix confirmed them.
  final int jumpsAccepted;

  /// Times the location stream stopped, how many were restarted, and how
  /// long the restarted ones took.
  final int streamLosses;
  final int streamRecoveries;
  final int lostMillis;

  /// The phone's power settings when the Trip started; null when unknown.
  final JourneyDeviceSettings? settings;

  /// The phone's power settings read again right before the most recent
  /// system pause (for now, only [JourneyPauseReason.locationLost] reads
  /// them) -- [settings] alone can miss a cause that only showed up partway
  /// through, like battery saver switching on after [settings] was read at
  /// the start.
  final JourneyDeviceSettings? settingsAtPause;

  int get userPauses =>
      pausesByReason[JourneyPauseReason.user.storageValue] ?? 0;

  /// Pauses the app made, whatever the reason.
  int get systemPauses {
    var total = 0;
    for (final reason in JourneyPauseReason.values) {
      if (reason.isSystem) total += pausesByReason[reason.storageValue] ?? 0;
    }
    return total;
  }

  JourneyQuality withPause(JourneyPauseReason reason) => copyWith(
    pausesByReason: {
      ...pausesByReason,
      reason.storageValue: (pausesByReason[reason.storageValue] ?? 0) + 1,
    },
  );

  JourneyQuality copyWith({
    Map<String, int>? pausesByReason,
    int? gaps,
    int? gapMillis,
    int? fixesAccepted,
    int? spikesDropped,
    int? jumpsAccepted,
    int? streamLosses,
    int? streamRecoveries,
    int? lostMillis,
    JourneyDeviceSettings? settings,
    JourneyDeviceSettings? settingsAtPause,
  }) => JourneyQuality(
    pausesByReason: pausesByReason ?? this.pausesByReason,
    gaps: gaps ?? this.gaps,
    gapMillis: gapMillis ?? this.gapMillis,
    fixesAccepted: fixesAccepted ?? this.fixesAccepted,
    spikesDropped: spikesDropped ?? this.spikesDropped,
    jumpsAccepted: jumpsAccepted ?? this.jumpsAccepted,
    streamLosses: streamLosses ?? this.streamLosses,
    streamRecoveries: streamRecoveries ?? this.streamRecoveries,
    lostMillis: lostMillis ?? this.lostMillis,
    settings: settings ?? this.settings,
    settingsAtPause: settingsAtPause ?? this.settingsAtPause,
  );

  Map<String, Object> toJson() => {
    'pauses': pausesByReason,
    'gaps': gaps,
    'gap_ms': gapMillis,
    'fixes_accepted': fixesAccepted,
    'spikes_dropped': spikesDropped,
    'jumps_accepted': jumpsAccepted,
    'stream_losses': streamLosses,
    'stream_recoveries': streamRecoveries,
    'lost_ms': lostMillis,
    if (settings != null) 'settings': settings!.toJson(),
    if (settingsAtPause != null) 'settings_at_pause': settingsAtPause!.toJson(),
  };

  String encode() => jsonEncode(toJson());

  /// Reads what [encode] wrote; null for missing or unreadable text.
  static JourneyQuality? decode(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      final data = jsonDecode(text);
      if (data is! Map<String, dynamic>) return null;
      int count(String key) {
        final value = data[key];
        return value is int && value >= 0 ? value : 0;
      }

      final pauses = <String, int>{};
      final raw = data['pauses'];
      if (raw is Map<String, dynamic>) {
        for (final entry in raw.entries) {
          final value = entry.value;
          if (value is int && value > 0) pauses[entry.key] = value;
        }
      }
      return JourneyQuality(
        pausesByReason: pauses,
        gaps: count('gaps'),
        gapMillis: count('gap_ms'),
        fixesAccepted: count('fixes_accepted'),
        spikesDropped: count('spikes_dropped'),
        jumpsAccepted: count('jumps_accepted'),
        streamLosses: count('stream_losses'),
        streamRecoveries: count('stream_recoveries'),
        lostMillis: count('lost_ms'),
        settings: JourneyDeviceSettings.fromJson(data['settings']),
        settingsAtPause: JourneyDeviceSettings.fromJson(
          data['settings_at_pause'],
        ),
      );
    } on FormatException {
      return null;
    }
  }
}
