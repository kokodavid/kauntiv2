import 'package:flutter/widgets.dart';

/// Opens County Detail for a county code. Supplied by `app/` so Map Home
/// never imports another feature's screens (architecture §2).
typedef OpenCountyDetail = void Function(BuildContext context, int countyCode);

/// Opens Place Detail for a place id. Supplied by `app/`.
typedef OpenPlaceDetail = void Function(BuildContext context, String placeId);

/// Opens driving directions in the maps app for a text destination.
/// Supplied by `app/`; resolves false when nothing could open it.
typedef OpenDirections = Future<bool> Function(String destination);
