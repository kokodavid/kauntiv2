import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';

/// The rounded search input used across the app (Explore, Add places).
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final hintStyle = AppTextStyles.searchInputText.copyWith(
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
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.searchInputText,
              // Every border variant is zeroed: the app's global input theme
              // would otherwise paint a second pill inside this one.
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: hint,
                hintStyle: hintStyle,
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
