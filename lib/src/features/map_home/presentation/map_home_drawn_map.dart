import 'package:flutter/material.dart';

import '../domain/map_home_models.dart';
import 'map_home_county_map.dart';
import 'map_home_links.dart';
import 'map_home_skeleton.dart';

Widget mapHomeDrawnMapFor(
  MapHomeBoardData? data, {
  required bool realLoading,
  OpenCountyDetail? onOpenCounty,
  required ValueChanged<bool> onInteractingChanged,
}) {
  if (data == null || realLoading) return const MapHomeLoadingMap();
  return MapHomeCountyMap(
    badges: data.countyBadges,
    homeCountySlug: data.homeCounty?.slug,
    onOpenCounty: onOpenCounty,
    onInteractingChanged: onInteractingChanged,
  );
}
