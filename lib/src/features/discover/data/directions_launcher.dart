import 'package:url_launcher/url_launcher.dart';

/// Opens driving directions in the phone's maps app (Google Maps URL, v1
/// parity), by coordinates when known, else by a text query.
class DirectionsLauncher {
  const DirectionsLauncher();

  Future<bool> open({double? latitude, double? longitude, String? query}) {
    final destination = latitude != null && longitude != null
        ? '$latitude,$longitude'
        : Uri.encodeComponent(query ?? '');
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$destination&travelmode=driving',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
