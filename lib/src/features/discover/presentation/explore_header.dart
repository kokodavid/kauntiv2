import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/explore_board.dart';
import 'explore_pill.dart';

/// The Field Guide v2 header actions. The content switch is deliberately
/// text-first, matching the design source and keeping both modes legible at
/// small widths.
class ExploreFieldGuideHeader extends StatelessWidget {
  const ExploreFieldGuideHeader({
    super.key,
    required this.mode,
    required this.savedCount,
    required this.onModeChanged,
    required this.onSavedTap,
  });

  final ExploreViewMode mode;
  final int savedCount;
  final ValueChanged<ExploreViewMode> onModeChanged;
  final VoidCallback onSavedTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(child: ExploreTopBar()),
        _ExploreModeSwitch(mode: mode, onChanged: onModeChanged),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: savedCount == 0 ? 'Saved' : 'Saved, $savedCount',
          child: IconButton(
            onPressed: onSavedTap,
            tooltip: 'Saved',
            icon: Icon(
              savedCount == 0
                  ? Icons.bookmark_border_rounded
                  : Icons.bookmark_rounded,
              color: savedCount == 0 ? AppColors.exploreText : AppColors.accent,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.exploreSurface,
              side: const BorderSide(color: AppColors.exploreBorder),
              fixedSize: const Size(44, 44),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExploreModeSwitch extends StatelessWidget {
  const _ExploreModeSwitch({required this.mode, required this.onChanged});

  final ExploreViewMode mode;
  final ValueChanged<ExploreViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.secondaryFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ExploreModeButton(
              label: 'Places',
              selected: mode == ExploreViewMode.places,
              onTap: () => onChanged(ExploreViewMode.places),
            ),
            _ExploreModeButton(
              label: 'Counties',
              selected: mode == ExploreViewMode.counties,
              onTap: () => onChanged(ExploreViewMode.counties),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreModeButton extends StatelessWidget {
  const _ExploreModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.exploreSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.chipLabel.copyWith(
              color: selected
                  ? AppColors.exploreText
                  : AppColors.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Explore's title row (v1 `_DiscoverTopBar`). v1's tier pill and avatar
/// were hard-coded placeholders ("Tier 1", a gradient dot), so they wait
/// for real tier and profile data instead of being copied over.
class ExploreTopBar extends StatelessWidget {
  const ExploreTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Explore', style: AppTextStyles.headingForeground);
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
              // Plain InputDecoration, not `.collapsed()`: collapsed only
              // clears the generic `border` field, so the app's global
              // inputDecorationTheme (explicit enabledBorder/focusedBorder,
              // filled white) still painted its own rounded border around
              // the field -- a "search inside a search" nested pill inside
              // this Container's own pill border. Zeroing every border
              // variant here removes it.
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: 'Search...',
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
    ExploreTab.mine: 'Mine',
    ExploreTab.unclaimed: 'Unclaimed',
    ExploreTab.saved: 'Saved',
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
            child: ExplorePill(
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
