/// Where a tapped push notification takes the user. The server only sends
/// values from this fixed list; an unknown one (an older app build reading a
/// newer payload) opens Home instead of failing.
enum PushDestinationKind {
  home,
  explore,
  county,
  place,
  badges,
  myPhotos,
  profile;

  static PushDestinationKind parse(String? value) => switch (value) {
    'explore' => explore,
    'county' => county,
    'place' => place,
    'badges' => badges,
    'my_photos' => myPhotos,
    'profile' => profile,
    _ => home,
  };
}

class PushDestination {
  const PushDestination(this.kind, [this.id]);

  /// Reads the `data` map FCM delivers with a notification.
  factory PushDestination.fromData(Map<String, Object?> data) {
    final id = data['dest_id'] as String?;
    return PushDestination(
      PushDestinationKind.parse(data['dest_kind'] as String?),
      id == null || id.isEmpty ? null : id,
    );
  }

  final PushDestinationKind kind;

  /// A county code or a place id, for the kinds that need one.
  final String? id;
}

/// A notification the user tapped (app in the background or closed).
class PushTap {
  const PushTap({required this.destination, this.eventId});

  factory PushTap.fromData(Map<String, Object?> data) {
    final eventId = data['event_id'] as String?;
    return PushTap(
      destination: PushDestination.fromData(data),
      eventId: eventId == null || eventId.isEmpty ? null : eventId,
    );
  }

  final PushDestination destination;
  final String? eventId;
}

/// A notification that arrived while the app was in front. It is shown as a
/// small in-app banner instead of a system alert.
class PushForegroundMessage {
  const PushForegroundMessage({
    required this.title,
    required this.body,
    required this.tap,
  });

  final String title;
  final String body;
  final PushTap tap;
}

/// What the phone currently allows. [unknown] means the question has not
/// been asked yet (or Firebase is not configured in this build).
enum PushPermission { granted, denied, unknown }

/// The Firebase project values for this build's environment. All empty
/// means push is simply off (a build without Firebase configured).
class FirebaseSettings {
  const FirebaseSettings({
    required this.projectId,
    required this.apiKey,
    required this.messagingSenderId,
    required this.androidAppId,
    required this.iosAppId,
  });

  final String projectId;
  final String apiKey;
  final String messagingSenderId;
  final String androidAppId;
  final String iosAppId;

  bool get isConfigured =>
      projectId.isNotEmpty &&
      apiKey.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      (androidAppId.isNotEmpty || iosAppId.isNotEmpty);
}
