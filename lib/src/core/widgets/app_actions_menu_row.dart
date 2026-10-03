import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import 'app_menu_action.dart';

class AppActionsMenuRow extends StatelessWidget {
  const AppActionsMenuRow({
    super.key,
    required this.action,
    required this.onSelected,
  });

  final AppMenuAction action;
  final ValueChanged<AppMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final color = action.isDestructive
        ? AppColors.danger
        : AppColors.buttonForeground;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        hoverColor: action.isDestructive
            ? AppColors.menuDangerItemPressed
            : AppColors.menuItemPressed,
        splashColor: action.isDestructive
            ? AppColors.menuDangerItemPressed
            : AppColors.menuItemPressed,
        highlightColor: action.isDestructive
            ? AppColors.menuDangerItemPressed
            : AppColors.menuItemPressed,
        onTap: () => onSelected(action),
        child: SizedBox(
          height: 46,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(action.icon, size: 18, color: color),
                const SizedBox(width: 12),
                Text(
                  action.label,
                  style: AppTextStyles.menuItemLabel.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
