import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';

/// A multi-select grid of icon tiles, shared by setup step 2 and the
/// standalone Interests editor: two columns, each tile with its own icon square and a
/// label. A picked tile gets a light-blue fill, a blue border and a check
/// badge, so the state never relies on colour alone. Each reads to a
/// screen reader as "Waterfalls and hikes, checkbox, checked".
class ChoiceTileGrid<T> extends StatelessWidget {
  const ChoiceTileGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.iconBuilder,
    required this.onToggle,
  });

  final List<T> options;
  final List<T> selected;
  final String Function(T option) labelOf;

  /// Builds the option's icon in the colour the tile wants for its state.
  final Widget Function(T option, Color color) iconBuilder;
  final ValueChanged<T> onToggle;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Room for the check badge that overhangs a tile's corner.
      clipBehavior: Clip.none,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 72,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        return _ChoiceTile(
          label: labelOf(option),
          iconBuilder: (color) => iconBuilder(option, color),
          isSelected: selected.contains(option),
          onTap: () => onToggle(option),
        );
      },
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.iconBuilder,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Widget Function(Color color) iconBuilder;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: isSelected,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.08)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isSelected ? AppColors.accent : AppColors.cardBorder,
                  width: 1.5,
                ),
              ),
              child: InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.pageBackground,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: iconBuilder(
                          isSelected
                              ? AppColors.accentForeground
                              : AppColors.foreground,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.buttonLabelSecondary.copyWith(
                            color: AppColors.foreground,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: AppColors.accentForeground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
