import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../application/plan_editor.dart';
import '../domain/plan_day.dart';
import '../domain/plan_failure.dart';
import '../domain/trip_plan.dart';
import 'add_places_page.dart';
import 'drop_pin_page.dart';
import 'plan_edit_sheets.dart';
import 'plan_pick_rows.dart';
import 'plan_sheet_frame.dart';
import 'start_search_page.dart';

enum _Stay { search, pin, place, clear }

/// "Add overnight stay" on a day: search for a hotel or an address, drop a
/// pin (an Airbnb, a relative's house), pick a Kaunti47 place, or clear it.
class PlanOvernightActions {
  PlanOvernightActions(this.context, this.ref, this.plan);

  final BuildContext context;
  final WidgetRef ref;
  final TripPlan plan;

  Future<void> run(PlanDay day) async {
    final choice = await showPlanSheet<_Stay>(
      context,
      (_) => _StaySheet(hasStay: day.hasOvernight),
    );
    if (choice == null || !context.mounted) return;
    final editor = ref.read(planEditorProvider);
    switch (choice) {
      case _Stay.search:
        final start = await showStartSearchPage(
          context,
          title: 'Where are you staying?',
        );
        if (start == null) return;
        await _report(
          editor.setOvernight(
            plan.id,
            day.id,
            label: start.displayLabel,
            lat: start.lat,
            lng: start.lng,
          ),
        );
      case _Stay.pin:
        final pin = await showDropPinPage(context);
        if (pin == null) return;
        await _report(
          editor.setOvernight(
            plan.id,
            day.id,
            label: pin.name,
            lat: pin.lat,
            lng: pin.lng,
          ),
        );
      case _Stay.place:
        final place = await showAddPlacesPage(
          context,
          title: 'Stay at a place',
        );
        if (place == null) return;
        await _report(editor.setOvernight(plan.id, day.id, placeId: place.id));
      case _Stay.clear:
        await _report(editor.setOvernight(plan.id, day.id));
    }
  }

  Future<void> _report(Future<PlanFailure?> change) async {
    final failure = await change;
    if (failure != null && context.mounted) {
      reportPlanFailure(context, failure);
    }
  }
}

class _StaySheet extends StatelessWidget {
  const _StaySheet({required this.hasStay});

  final bool hasStay;

  Widget _icon(IconData icon) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AppColors.accentTint,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, size: 20, color: AppColors.accent),
  );

  @override
  Widget build(BuildContext context) => PlanSheetFrame(
    title: 'Where do you stay tonight?',
    subtitle: 'Anyone on this plan will see it.',
    closeButton: true,
    children: [
      PlanPickRow(
        title: 'Search for a stay',
        detail: 'A hotel, lodge, camp or address',
        leading: _icon(Icons.search),
        onTap: () => Navigator.of(context).pop(_Stay.search),
      ),
      PlanPickRow(
        title: 'Drop a pin',
        detail: 'An Airbnb, a home, anywhere without a listing',
        leading: _icon(Icons.place_outlined),
        onTap: () => Navigator.of(context).pop(_Stay.pin),
      ),
      PlanPickRow(
        title: 'A Kaunti47 place',
        detail: 'A camp, lodge or other place on the app',
        leading: _icon(Icons.landscape_outlined),
        onTap: () => Navigator.of(context).pop(_Stay.place),
      ),
      if (hasStay)
        PlanPickLinkRow(
          label: 'Remove the stay',
          icon: Icons.remove_circle_outline,
          onTap: () => Navigator.of(context).pop(_Stay.clear),
        ),
    ],
  );
}
