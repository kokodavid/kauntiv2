import 'package:url_launcher/url_launcher.dart';

/// Opens driving directions in the phone's maps app (Google Maps URL, v1
/// parity), by coordinates when known, else by a text query.
class DirectionsLauncher {
  const DirectionsLauncher();

  /// [waypoints] are "lat,lng" stops to pass, in order, before the
  /// destination.
  Future<bool> open({
    double? latitude,
    double? longitude,
    String? query,
    List<String> waypoints = const [],
  }) {
    final destination = latitude != null && longitude != null
        ? '$latitude,$longitude'
        : Uri.encodeComponent(query ?? '');
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$destination&travelmode=driving'
      '${waypoints.isEmpty ? '' : '&waypoints=${waypoints.join('%7C')}'}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> openExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
