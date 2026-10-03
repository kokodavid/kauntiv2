part of 'journey_history_filters.dart';

/// "All counties" (or the chosen one, or "N counties") - opens a sheet
/// listing every county any Trip crossed, with trip counts and a "Show N
/// trips" confirm button, to narrow the list to Trips crossing any of the
/// picked counties.
class _CountyFilterPill extends StatelessWidget {
  const _CountyFilterPill({
    required this.counties,
    required this.countTripsFor,
    required this.selected,
    required this.onSelected,
  });

  final List<JourneyCountyOption> counties;
  final int Function(Set<String> counties) countTripsFor;
  final Set<String> selected;
  final ValueChanged<Set<String>> onSelected;

  Future<void> _openSheet(BuildContext context) async {
    final current = selected;
    // useRootNavigator: true - same as JourneyRouteChoiceSheet and the
    // transport-mode picker - so this sheet sits above AppShell's whole
    // Stack rather than inside the active tab's own nested Navigator,
    // which renders underneath the shell's floating AppBottomNav.
    final chosen = await showModalBottomSheet<Set<String>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _CountySheet(
        counties: counties,
        countTripsFor: countTripsFor,
        current: current,
      ),
    );
    // A null result means the sheet was dismissed (back gesture, tap
    // outside) rather than confirmed with the button - keep whatever was
    // already selected rather than clearing it.
    if (!context.mounted || chosen == null) return;
    if (!setEquals(chosen, current)) onSelected(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final active = selected.isNotEmpty;
    final label = switch (selected.length) {
      0 => 'All counties',
      1 => selected.first,
      _ => '${selected.length} counties',
    };
    return Material(
      color: active ? AppColors.accent : AppColors.exploreSurface,
      shape: StadiumBorder(
        side: BorderSide(
          color: active ? AppColors.accent : AppColors.exploreBorder,
        ),
      ),
      child: InkWell(
        onTap: counties.isEmpty ? null : () => _openSheet(context),
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypeScale.pill.copyWith(
                  color: active ? Colors.white : AppColors.mutedForeground,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: active ? Colors.white : AppColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
