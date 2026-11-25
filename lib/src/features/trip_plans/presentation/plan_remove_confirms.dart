import 'package:flutter/material.dart';

import '../domain/plan_day.dart';
import 'plan_edit_sheets.dart';

/// The "are you sure" sheets for taking things out of a plan. Each says
/// where the place goes, so nobody loses one by accident.
abstract final class PlanRemoveConfirms {
  /// A stop goes back to Places to visit.
  static Future<bool> stopToPlaces(
    BuildContext context,
    PlanDay day,
    PlanStop stop,
  ) => showPlanConfirm(
    context,
    title: 'Remove ${stop.place.name} from ${day.displayTitle}?',
    message: 'It moves back to Places to visit, so nothing is lost.',
    action: 'Remove from day',
  );

  /// A stop leaves the plan altogether.
  static Future<bool> stopFromPlan(
    BuildContext context,
    PlanDay day,
    PlanStop stop,
  ) => showPlanConfirm(
    context,
    title: 'Remove ${stop.place.name} from the plan?',
    message:
        'It leaves ${day.displayTitle} and Places to visit. You can add it '
        'again later.',
    action: 'Remove from plan',
  );

  /// A day goes; its stops move to Places to visit and later days move up.
  static Future<bool> day(
    BuildContext context,
    PlanDay day, {
    required bool laterDays,
  }) {
    final count = day.stops.length;
    final stops = count == 1 ? 'Its 1 stop moves' : 'Its $count stops move';
    final message = count == 0
        ? 'The day is empty.'
        : '$stops to Places to visit, so nothing is lost.'
              '${laterDays ? ' Later days move up one.' : ''}';
    return showPlanConfirm(
      context,
      title: 'Remove ${day.displayTitle}?',
      message: message,
      action: 'Remove day',
    );
  }
}
