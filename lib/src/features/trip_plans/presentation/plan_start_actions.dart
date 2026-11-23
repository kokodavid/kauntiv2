import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../application/plan_editor.dart';
import '../domain/trip_plan.dart';
import 'add_places_page.dart';
import 'drop_pin_page.dart';
import 'plan_edit_sheets.dart';
import 'plan_pick_rows.dart';
import 'plan_sheet_frame.dart';
import 'start_search_page.dart';

enum _Start { here, search, pin, place }

/// "Change start" on Day 1: where the phone is, a searched place, a dropped
/// pin or a Kaunti47 place.
class PlanStartActions {
  PlanStartActions(this.context, this.ref, this.plan);

  final BuildContext context;
  final WidgetRef ref;
  final TripPlan plan;

  Future<void> run() async {
    final choice = await showPlanSheet<_Start>(context, (_) => const _StartSheet());
    if (choice == null || !context.mounted) return;
    final PlanStart? start;
    switch (choice) {
      case _Start.here:
        start = PlanStart.currentLocation;
      case _Start.search:
        start = await showStartSearchPage(context);
      case _Start.pin:
        final pin = await showDropPinPage(context);
        start = pin == null
            ? null
            : PlanStart(
                kind: PlanStartKind.point,
                label: pin.name,
                lat: pin.lat,
                lng: pin.lng,
              );
      case _Start.place:
        final place = await showAddPlacesPage(
          context,
          title: 'Start from a place',
        );
        start = place == null
            ? null
            : PlanStart(kind: PlanStartKind.place, place: place);
    }
    if (start == null) return;
    final failure = await ref.read(planEditorProvider).setStart(plan.id, start);
    if (failure != null && context.mounted) {
      reportPlanFailure(context, failure);
    }
  }
}

class _StartSheet extends StatelessWidget {
  const _StartSheet();

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
    title: 'Where does Day 1 start?',
    subtitle: 'The first road is worked out from here.',
    closeButton: true,
    children: [
      PlanPickRow(
        title: 'Where you are',
        detail: 'Your phone\'s location when you start',
        leading: _icon(Icons.my_location),
        onTap: () => Navigator.of(context).pop(_Start.here),
      ),
      PlanPickRow(
        title: 'Search for a place',
        detail: 'An address, landmark, hotel or town',
        leading: _icon(Icons.search),
        onTap: () => Navigator.of(context).pop(_Start.search),
      ),
      PlanPickRow(
        title: 'Drop a pin',
        detail: 'Anywhere without a listing',
        leading: _icon(Icons.place_outlined),
        onTap: () => Navigator.of(context).pop(_Start.pin),
      ),
      PlanPickRow(
        title: 'A Kaunti47 place',
        detail: 'Start from a place on the app',
        leading: _icon(Icons.landscape_outlined),
        onTap: () => Navigator.of(context).pop(_Start.place),
      ),
    ],
  );
}
