import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// A quick way to narrow a long Trip list by when it happened.
enum JourneyDateFilter {
  all,
  thisMonth,
  lastMonth;

  String get label => switch (this) {
    JourneyDateFilter.all => 'All',
    JourneyDateFilter.thisMonth => 'This month',
    JourneyDateFilter.lastMonth => 'Last month',
  };
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
              decoration: InputDecoration.collapsed(
                hintText: 'Search trips...',
                hintStyle: hint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JourneyHistoryDateFilters extends StatelessWidget {
  const JourneyHistoryDateFilters({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final JourneyDateFilter selected;
  final ValueChanged<JourneyDateFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in JourneyDateFilter.values) ...[
            if (filter != JourneyDateFilter.values.first)
              const SizedBox(width: 8),
            _DatePill(
              label: filter.label,
              selected: filter == selected,
              onTap: () => onSelected(filter),
            ),
          ],
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
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
