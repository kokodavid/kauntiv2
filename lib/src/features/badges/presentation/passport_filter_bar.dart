import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/passport_book.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// Search and the filter chips under the next-stamp card.
class PassportFilterBar extends StatelessWidget {
  const PassportFilterBar({
    super.key,
    required this.book,
    required this.filter,
    required this.query,
    required this.onFilter,
    required this.onQuery,
  });

  final PassportBook book;
  final PassportFilter filter;
  final String query;
  final ValueChanged<PassportFilter> onFilter;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The same pill as Explore's search field.
        Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.exploreSurface,
            border: Border.all(color: AppColors.trackInactive),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search,
                size: 16,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  onChanged: onQuery,
                  textInputAction: TextInputAction.search,
                  style: AppTextStyles.searchInputText,
                  // Every border variant off: the app's input theme would
                  // otherwise paint a second border inside this pill.
                  decoration: InputDecoration(
                    isCollapsed: true,
                    hintText: 'Search ${book.total} counties',
                    hintStyle: AppTextStyles.searchInputText.copyWith(
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
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: PassportFilter.values.length,
            separatorBuilder: (context, i) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final value = PassportFilter.values[i];
              final selected = value == filter;
              return GestureDetector(
                onTap: () => onFilter(value),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected ? PassportInk.primary : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? PassportInk.primary
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Text(
                    value == PassportFilter.all
                        ? 'All ${book.countFor(value)}'
                        : '${value.label} · ${book.countFor(value)}',
                    style: passportText(
                      12.5,
                      weight: FontWeight.w600,
                      color: selected ? Colors.white : PassportInk.secondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
