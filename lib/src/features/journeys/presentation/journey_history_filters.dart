import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/journey_grouping.dart';

part 'journey_history_filters_pill_divider.dart';
part 'journey_history_filters_county_filter_pill.dart';
part 'journey_history_filters_county_sheet.dart';
part 'journey_history_filters_county_sheet_state.dart';
part 'journey_history_filters_check_dot.dart';
part 'journey_history_filters_on_this_phone_pill.dart';
part 'journey_history_filters_filter_pill.dart';

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
              onTap: () =>
                  onLengthSelected(bucket == lengthFilter ? null : bucket),
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
