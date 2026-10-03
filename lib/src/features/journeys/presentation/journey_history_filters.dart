import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/journey_grouping.dart';

/// A quick way to narrow a long Trip list by when it happened.
enum JourneyDateFilter {
  all,
  thisMonth,
  lastMonth,
  threeMonths;

  String get label => switch (this) {
    JourneyDateFilter.all => 'All',
    JourneyDateFilter.thisMonth => 'This month',
    JourneyDateFilter.lastMonth => 'Last month',
    JourneyDateFilter.threeMonths => '3 months',
  };

  /// Whether [startedAt] (local) falls inside this window. [all] always
  /// matches - callers combine it with other filters instead of branching.
  bool matches(DateTime startedAt) {
    final local = startedAt.toLocal();
    final now = DateTime.now();
    switch (this) {
      case JourneyDateFilter.all:
        return true;
      case JourneyDateFilter.thisMonth:
        return local.year == now.year && local.month == now.month;
      case JourneyDateFilter.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1);
        return local.year == lastMonth.year && local.month == lastMonth.month;
      case JourneyDateFilter.threeMonths:
        final cutoff = DateTime(now.year, now.month - 2);
        return !local.isBefore(DateTime(cutoff.year, cutoff.month));
    }
  }
}

/// One county in the filter sheet's list: its code, name and how many of
/// the (unfiltered) Trips crossed it.
class JourneyCountyOption {
  const JourneyCountyOption({
    required this.name,
    required this.code,
    required this.tripCount,
  });

  final String name;
  final int code;
  final int tripCount;
}

class JourneyHistorySearchField extends StatelessWidget {
  const JourneyHistorySearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hint = AppTypeScale.body.copyWith(color: AppColors.mutedForeground);
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.exploreSurface,
        border: Border.all(color: AppColors.trackInactive),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: AppColors.mutedForeground),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppTypeScale.body,
              // See explore_header.dart's ExploreSearchField: `.collapsed()`
              // doesn't clear enabledBorder/focusedBorder, so the app's
              // global inputDecorationTheme border was still painting a
              // second, nested box around the field inside this
              // Container's own pill. Spelling out every border variant
              // removes it.
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: 'Search trips, places, counties',
                hintStyle: hint,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The always-visible filter strip: county, date window, Trip length and
/// "on this phone", sharing one horizontally-scrolling row of pills. Date
/// and length are each a single choice (tapping the active one clears
/// it); county opens a sheet to pick any number of counties (a Trip
/// matches if it crossed at least one of them); "On this phone" is a
/// separate, independent toggle.
class JourneyHistoryFilterBar extends StatelessWidget {
  const JourneyHistoryFilterBar({
    super.key,
    required this.counties,
    required this.countTripsFor,
    required this.selectedCounties,
    required this.onCountiesSelected,
    required this.dateFilter,
    required this.onDateSelected,
    required this.lengthFilter,
    required this.onLengthSelected,
    this.onlyOnThisPhone = false,
    this.onToggleOnThisPhone,
  });

  /// Counties any Trip in the (unfiltered) list crossed, with how many
  /// Trips crossed each one, for the sheet.
  final List<JourneyCountyOption> counties;

  /// How many of the (unfiltered) Trips crossed at least one county in
  /// the given set - the empty set means "every Trip" - shown live on the
  /// sheet's confirm button as the user taps rows.
  final int Function(Set<String> counties) countTripsFor;

  final Set<String> selectedCounties;
  final ValueChanged<Set<String>> onCountiesSelected;

  final JourneyDateFilter dateFilter;
  final ValueChanged<JourneyDateFilter> onDateSelected;

  final JourneyLengthBucket? lengthFilter;
  final ValueChanged<JourneyLengthBucket?> onLengthSelected;

  /// Whether the "On this phone" chip (still waiting to upload) is active.
  final bool onlyOnThisPhone;

  /// Null hides the "On this phone" chip entirely (nothing local to show).
  final VoidCallback? onToggleOnThisPhone;

  @override
  Widget build(BuildContext context) {
    final toggleOnThisPhone = onToggleOnThisPhone;
    final dateFilters = JourneyDateFilter.values.where(
      (filter) => filter != JourneyDateFilter.all,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CountyFilterPill(
            counties: counties,
            countTripsFor: countTripsFor,
            selected: selectedCounties,
            onSelected: onCountiesSelected,
          ),
          const _PillDivider(),
          for (final filter in dateFilters) ...[
            if (filter != dateFilters.first) const SizedBox(width: 8),
            _FilterPill(
              label: filter.label,
              selected: filter == dateFilter,
              onTap: () => onDateSelected(
                filter == dateFilter ? JourneyDateFilter.all : filter,
              ),
            ),
          ],
          const _PillDivider(),
          for (final bucket in JourneyLengthBucket.values) ...[
            if (bucket != JourneyLengthBucket.values.first)
              const SizedBox(width: 8),
            _FilterPill(
              label: bucket.title,
              selected: bucket == lengthFilter,
              onTap: () => onLengthSelected(
                bucket == lengthFilter ? null : bucket,
              ),
            ),
          ],
          if (toggleOnThisPhone != null) ...[
            const _PillDivider(),
            _OnThisPhonePill(
              selected: onlyOnThisPhone,
              onTap: toggleOnThisPhone,
            ),
          ],
        ],
      ),
    );
  }
}

/// A thin vertical rule separating groups of pills in the filter strip.
class _PillDivider extends StatelessWidget {
  const _PillDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(width: 1, height: 20, color: AppColors.cardBorder),
    );
  }
}

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

/// The county picker sheet itself: a header ("Counties" / "You've been to
/// N of 47"), one row per county with its code, name, Trip count and a
/// check mark, and a sticky "Show N trips" button that confirms the pick
/// (any number of counties, or none) rather than applying on tap. A Trip
/// shows if it crossed at least one of the checked counties.
class _CountySheet extends StatefulWidget {
  const _CountySheet({
    required this.counties,
    required this.countTripsFor,
    required this.current,
  });

  final List<JourneyCountyOption> counties;
  final int Function(Set<String> counties) countTripsFor;
  final Set<String> current;

  @override
  State<_CountySheet> createState() => _CountySheetState();
}

class _CountySheetState extends State<_CountySheet> {
  late final Set<String> _selected = Set.of(widget.current);

  void _toggle(String name) {
    setState(() {
      if (!_selected.remove(name)) _selected.add(name);
    });
  }

  static String _tripsLabel(int count) =>
      count == 1 ? '1 trip' : '$count trips';

  @override
  Widget build(BuildContext context) {
    final shownCount = widget.countTripsFor(_selected);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Text('Counties', style: AppTypeScale.sectionTitle),
                  ),
                  Text(
                    "You've been to ${widget.counties.length} of "
                    '${CountyPaths.all.length}',
                    style: AppTypeScale.meta.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: widget.counties.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  color: AppColors.cardBorder,
                  indent: 20,
                  endIndent: 20,
                ),
                itemBuilder: (context, index) {
                  final county = widget.counties[index];
                  final isSelected = _selected.contains(county.name);
                  return InkWell(
                    onTap: () => _toggle(county.name),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              county.code.toString().padLeft(3, '0'),
                              style: AppTypeScale.meta.copyWith(
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              county.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypeScale.cardTitle,
                            ),
                          ),
                          Text(
                            _tripsLabel(county.tripCount),
                            style: AppTypeScale.meta.copyWith(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _CheckDot(selected: isSelected),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Show ${_tripsLabel(shownCount)}',
                    style: AppTextStyles.buttonLabel.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The checkbox-style mark on a county row - a filled, checked square when
/// picked, since any number of counties can be picked at once.
class _CheckDot extends StatelessWidget {
  const _CheckDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.cardBorder,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

/// "On this phone": Trips still waiting to upload. The orange dot flags it
/// as a device-local state rather than a date window.
class _OnThisPhonePill extends StatelessWidget {
  const _OnThisPhonePill({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('journeyOnThisPhoneFilter'),
      color: selected ? AppColors.accent : AppColors.exploreSurface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.exploreBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : AppColors.pendingFill,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'On this phone',
                maxLines: 1,
                style: AppTypeScale.pill.copyWith(
                  color: selected ? Colors.white : AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single-select pill, shared by the date and length filter groups.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : AppColors.exploreSurface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.exploreBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            maxLines: 1,
            style: AppTypeScale.pill.copyWith(
              color: selected ? Colors.white : AppColors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}
