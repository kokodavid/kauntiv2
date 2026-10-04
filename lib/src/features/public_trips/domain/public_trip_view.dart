import 'public_trip_json.dart';
import 'public_trip_owner_view.dart';

/// Who published a trip, as other people see them. [id] is an opaque author
/// ID used only for blocking; it is never the account ID.
class PublicTripAuthor {
  const PublicTripAuthor({
    required this.id,
    required this.displayName,
    this.handle,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? handle;
  final String? avatarUrl;

  factory PublicTripAuthor.fromJson(Map<String, dynamic>? json) {
    final name = (json?['display_name'] as String?)?.trim() ?? '';
    return PublicTripAuthor(
      id: json?['id'] as String? ?? '',
      displayName: name.isEmpty ? 'A Kaunti47 explorer' : name,
      handle: json?['handle'] as String?,
      avatarUrl: json?['avatar_url'] as String?,
    );
  }
}

/// A sanitized photo. The image itself is fetched separately with a
/// short-lived link; the trip data never carries a URL.
class PublicTripPhoto {
  const PublicTripPhoto({
    required this.id,
    this.latitude,
    this.longitude,
    this.width,
    this.height,
  });

  final String id;
  final double? latitude;
  final double? longitude;
  final int? width;
  final int? height;

  bool get hasPlace => latitude != null && longitude != null;
}

/// An approved public trip as a viewer sees it: the trimmed route, the
/// moments and photos the owner chose, and the author. It never holds times,
/// the real start or end, or any private identifier.
class PublicTripView {
  const PublicTripView({
    required this.id,
    required this.revision,
    required this.title,
    required this.author,
    this.tripDate,
    this.transportMode,
    this.distanceMeters = 0,
    this.counties = const [],
    this.routeLines = const [],
    this.moments = const [],
    this.photos = const [],
    this.unclaimedCounties = 0,
  });

  final String id;
  final int revision;
  final String title;
  final PublicTripAuthor author;

  /// The calendar day the trip started; never a time.
  final DateTime? tripDate;
  final String? transportMode;
  final double distanceMeters;
  final List<PublicTripCounty> counties;
  final List<List<PublicTripPoint>> routeLines;
  final List<PublicTripMoment> moments;
  final List<PublicTripPhoto> photos;

  /// For Home's row: how many of this route's counties the viewer has not
  /// explored yet. Zero when the server did not say.
  final int unclaimedCounties;

  bool get isWalk => transportMode == 'walk';

  /// Where the public route begins: the approved point directions go to. It
  /// is already trimmed away from the owner's real start.
  PublicTripPoint? get publicStart {
    for (final line in routeLines) {
      if (line.isNotEmpty) return line.first;
    }
    return null;
  }

  factory PublicTripView.fromJson(Map<String, dynamic> json) {
    return PublicTripView(
      id: json['id'] as String,
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      author: PublicTripAuthor.fromJson(
        json['author'] as Map<String, dynamic>?,
      ),
      tripDate: DateTime.tryParse(json['trip_date'] as String? ?? ''),
      transportMode: json['transport_mode'] as String?,
      distanceMeters: (json['distance_m'] as num?)?.toDouble() ?? 0,
      counties: publicTripCounties(json['counties']),
      routeLines: publicTripRouteLines(json['route']),
      moments: publicTripMoments(json['moments']),
      photos: [
        for (final raw in json['photos'] as List<dynamic>? ?? const [])
          PublicTripPhoto(
            id: (raw as Map<String, dynamic>)['id'] as String,
            latitude: (raw['latitude'] as num?)?.toDouble(),
            longitude: (raw['longitude'] as num?)?.toDouble(),
            width: (raw['width'] as num?)?.toInt(),
            height: (raw['height'] as num?)?.toInt(),
          ),
      ],
      unclaimedCounties: (json['unclaimed_counties'] as num?)?.toInt() ?? 0,
    );
  }
}
