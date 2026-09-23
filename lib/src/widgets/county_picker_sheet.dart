import 'package:flutter/material.dart';

import '../counties/county_paths.dart';
import '../design/app_colors.dart';
import '../design/app_text_styles.dart';
import 'county_list_tile.dart';

/// The v2 "pick your county" search sheet (Figma node 235:6967, "Karibu -
/// search"). A modal bottom sheet -- drag handle, heading, a search
/// field, and the full county list filtered live as you type. Built once
/// here so any screen that needs a county picker can reuse it instead of
/// re-deriving search+list each time; [OnboardingHomeCountyPage] is the
/// first caller.
///
/// Figma shows this sheet floating near the top of the screen over a
/// blurred dark backdrop, not anchored to the bottom edge. This builds it
/// as a standard bottom-anchored modal sheet instead (rounded top
/// corners, a plain dim instead of a true gaussian blur) -- the
/// search+list+drag-handle content matches exactly, and a bottom sheet is
/// the idiomatic, better-supported Flutter pattern for a picker like this
/// over a hand-rolled floating dialog.
class CountyPickerSheet extends StatefulWidget {
  const CountyPickerSheet({super.key, required this.selectedCounty});

  final CountyPath? selectedCounty;

  static Future<CountyPath?> show(
    BuildContext context, {
    required CountyPath? selectedCounty,
  }) {
    return showModalBottomSheet<CountyPath>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: const Color(0x40000000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => CountyPickerSheet(selectedCounty: selectedCounty),
    );
  }

  @override
  State<CountyPickerSheet> createState() => _CountyPickerSheetState();
}

class _CountyPickerSheetState extends State<CountyPickerSheet> {
  final _controller = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<CountyPath> get _results {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return CountyPaths.all;
    }
    return CountyPaths.all
        .where((county) => county.name.toLowerCase().contains(normalized))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search for your county',
                      style: AppTextStyles.headingForeground,
                    ),
                    const SizedBox(height: 12),
                    _CountySearchField(
                      controller: _controller,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: Text(
                          'No county matches that search.',
                          style: AppTextStyles.listItemSubtitle,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final county = results[index];
                          return CountyListTile(
                            county: county,
                            selected: county == widget.selectedCounty,
                            showDivider: index != results.length - 1,
                            onTap: () => Navigator.of(context).pop(county),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountySearchField extends StatelessWidget {
  const _CountySearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: AppColors.mutedForeground),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.searchInputText,
              decoration: InputDecoration.collapsed(
                hintText: 'Search...',
                hintStyle: AppTextStyles.searchInputText.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
