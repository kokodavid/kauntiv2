import 'package:flutter/widgets.dart';

import '../../../core/widgets/app_photo_parts.dart';

/// Opens County Detail for a county code. Supplied by `app/` so Map Home
/// never imports another feature's screens (architecture §2).
typedef OpenCountyDetail = void Function(BuildContext context, int countyCode);

/// Opens Place Detail for a place id. Supplied by `app/`.
typedef OpenPlaceDetail = void Function(BuildContext context, String placeId);

/// Opens driving directions in the maps app. Supplied by `app/`.
typedef OpenDirections = AppOpenDirections;

/// Opens Explore on its UNCLAIMED list. Supplied by `app/`.
typedef OpenAllUnclaimed = void Function(BuildContext context);
