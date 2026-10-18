import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/explore_board.dart';

/// The dock's search input: a 44 pt white pill with a hairline border.
class ExploreDockSearchBox extends StatelessWidget {
  const ExploreDockSearchBox({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.exploreSurface,
        border: Border.all(color: AppColors.trackInactive),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              // Tapping anywhere else, or the keyboard's Search key, puts
              // the keyboard away (iOS has no back button to do it).
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              style: const TextStyle(
                fontFamily: AppTypeScale.family,
                fontSize: 14,
                color: AppColors.exploreText,
              ),
              // Every border variant is cleared: the app's input theme
              // would otherwise draw a pill inside this pill.
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: AppTypeScale.family,
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                ),
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

/// The dock's round filter button: soft blue, solid with a count when sheet
/// filters are on, and a clear (x) while the traveller is typing.
class ExploreDockFilterButton extends StatelessWidget {
  const ExploreDockFilterButton({
    super.key,
    required this.mode,
    required this.typing,
    required this.filterCount,
    required this.onFilter,
    required this.onClear,
  });

  final ExploreViewMode mode;
  final bool typing;
  final int filterCount;
  final VoidCallback onFilter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final active = filterCount > 0 && !typing;
    return Tooltip(
      message: typing
          ? 'Clear search'
          : mode == ExploreViewMode.places
          ? 'Filter places'
          : 'Filter counties',
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: typing ? onClear : onFilter,
          behavior: HitTestBehavior.opaque,
          child: SizedBox.square(
            dimension: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? AppColors.accent : AppColors.accentTint,
                    ),
                    child: Icon(
                      typing ? Icons.close_rounded : Icons.tune_rounded,
                      size: 21,
                      color: active ? Colors.white : AppColors.accent,
                    ),
                  ),
                ),
                if (active)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '$filterCount',
                        style: const TextStyle(
                          fontFamily: AppTypeScale.family,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
