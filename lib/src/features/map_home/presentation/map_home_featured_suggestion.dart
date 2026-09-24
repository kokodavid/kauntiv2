import 'package:flutter/material.dart';

import '../../../core/widgets/app_feature_card.dart';
import '../../../core/widgets/app_photo_parts.dart';
import '../domain/map_home_models.dart';
import '../domain/map_home_promotion.dart';
import 'map_home_links.dart';
import 'map_home_suggestion_media.dart';

/// For You's top card for the promoted place: its AD label, place photo
/// and stats. Opens Place Detail when that link is wired.
Widget mapHomePromotionCard(
  MapHomePromotedPlace promotion, {
  OpenPlaceDetail? onOpenPlace,
  OpenCountyDetail? onOpenCounty,
  OpenDirections? onRoute,
}) => Builder(
  builder: (context) => AppFeatureCard(
    county: promotion.county,
    photoTitle: promotion.placeName,
    photoCaption: '${promotion.county.name} County',
    photoUrl: promotion.photoUrl,
    label: promotion.disclosureLabel,
    line: promotion.summary ?? 'Sponsored by ${promotion.sponsorName}',
    stats: promotion.stats,
    actions: [
      if (onRoute != null)
        AppPhotoButton(
          onPressed: () =>
              openRoute(context, promotion.directionsQuery, onRoute),
        ),
    ],
    onTap: () => onOpenPlace != null
        ? onOpenPlace(context, promotion.placeId)
        : openCountyOrNote(context, promotion.county, onOpenCounty),
  ),
);

/// For You's top card when nothing is promoted: the best suggestion.
/// Opens County Detail.
Widget mapHomeSuggestionCard(
  MapHomeSuggestion suggestion, {
  OpenCountyDetail? onOpenCounty,
  OpenDirections? onRoute,
}) => Builder(
  builder: (context) => AppFeatureCard(
    county: suggestion.county,
    photoTitle: suggestion.title,
    photoCaption: suggestion.placeName == null
        ? suggestion.distanceAway
        : '${suggestion.county.name} County',
    photoUrl: suggestion.highlightImageUrl,
    line: '${suggestion.reasonLabel} · ${suggestion.distanceAway}',
    stats: suggestion.stats,
    actions: [
      if (onRoute != null)
        AppPhotoButton(
          onPressed: () =>
              openRoute(context, suggestion.directionsQuery, onRoute),
        ),
    ],
    onTap: () => openCountyOrNote(context, suggestion.county, onOpenCounty),
  ),
);
