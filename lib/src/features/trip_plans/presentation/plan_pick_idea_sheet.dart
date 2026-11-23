import 'package:flutter/material.dart';

import '../domain/plan_day.dart';
import '../domain/trip_plan.dart';
import 'plan_pick_rows.dart';
import 'plan_place_thumb.dart';
import 'plan_sheet_frame.dart';
import 'plan_stop_row.dart';

/// "Add to Day 1": pick one of the plan's Places to visit. Each row shows
/// the photo, the place, and where it will land on the day.
Future<PlanIdea?> showPlanPickIdeaSheet(
  BuildContext context,
  TripPlan plan,
  PlanDay day,
) => showPlanSheet<PlanIdea>(
  context,
  (sheet) => PlanSheetFrame(
    title: 'Add to ${day.displayTitle}',
    subtitle: 'Pick a place from Places to visit. It goes in as the last stop.',
    children: [
      for (final idea in plan.places)
        PlanPickRow(
          leading: PlanPlaceThumb(
            url: idea.place.thumbnailUrl,
            size: 40,
            custom: idea.place.isCustom,
          ),
          title: idea.place.name,
          detail: planPlaceMeta(
            idea.place.type,
            idea.place.countyCode,
            custom: idea.place.isCustom,
          ),
          trailing: const Icon(Icons.add_circle_outline, size: 20),
          onTap: () => Navigator.of(sheet).pop(idea),
        ),
    ],
  ),
);
