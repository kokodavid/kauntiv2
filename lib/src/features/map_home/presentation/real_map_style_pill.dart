import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import 'real_map_layers.dart';

/// The base-style picker: a white pill with a round thumbnail and a name
/// for each style. The chosen one gets an accent ring and a soft tint.
class RealMapStylePill extends StatelessWidget {
  const RealMapStylePill({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final RealMapBaseStyle selected;
  final ValueChanged<RealMapBaseStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final style in RealMapBaseStyle.values)
            _StyleOption(
              style: style,
              selected: style == selected,
              onTap: () => onSelected(style),
            ),
        ],
      ),
    );
  }
}

class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final RealMapBaseStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${style.label} map',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.accent : AppColors.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    style.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: AppColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                style.label,
                style: TextStyle(
                  fontFamily: AppTypeScale.family,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.accent : AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
