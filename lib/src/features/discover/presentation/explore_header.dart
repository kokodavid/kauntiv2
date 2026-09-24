import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/explore_board.dart';
import 'explore_styles.dart';

/// Explore's title row (v1 `_DiscoverTopBar`). v1's tier pill and avatar
/// were hard-coded placeholders ("Tier 1", a gradient dot), so they wait
/// for real tier and profile data instead of being copied over.
class ExploreTopBar extends StatelessWidget {
  const ExploreTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Discover', style: AppTextStyles.headingForeground);
  }
}

/// The rounded search input shared across Explore's tabs.
class ExploreSearchField extends StatefulWidget {
  const ExploreSearchField({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<ExploreSearchField> createState() => _ExploreSearchFieldState();
}

class _ExploreSearchFieldState extends State<ExploreSearchField> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hint = AppTextStyles.searchInputText.copyWith(
      color: AppColors.mutedForeground,
    );
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
              controller: _controller,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.searchInputText,
              decoration: InputDecoration.collapsed(
                hintText: 'Search...',
                hintStyle: hint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// MINE / UNCLAIMED / SAVED pills with counts. A missing count shows the
/// label alone.
class ExploreTabChips extends StatelessWidget {
  const ExploreTabChips({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final ExploreTab selected;
  final Map<ExploreTab, int?> counts;
  final ValueChanged<ExploreTab> onSelected;

  static const _labels = {
    ExploreTab.mine: 'MINE',
    ExploreTab.unclaimed: 'UNCLAIMED',
    ExploreTab.saved: 'SAVED',
  };

  // v1 widths: the pills share the row roughly 22 / 45 / 27.
  static const _flex = {
    ExploreTab.mine: 22,
    ExploreTab.unclaimed: 45,
    ExploreTab.saved: 27,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tab in ExploreTab.values) ...[
          if (tab != ExploreTab.values.first) const SizedBox(width: 8),
          Expanded(
            flex: _flex[tab]!,
            child: _Chip(
              label: switch (counts[tab]) {
                final count? => '${_labels[tab]} · $count',
                null => _labels[tab]!,
              },
              selected: tab == selected,
              onTap: () => onSelected(tab),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.exploreSurface;
    return Material(
      color: color,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.exploreBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7.25),
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: ExploreStyles.tabChip(selected: selected),
          ),
        ),
      ),
    );
  }
}
