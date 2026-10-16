import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/explore_board.dart';
import 'explore_dock_parts.dart';

/// The Field Guide dock: one translucent shell above the tab bar with the
/// search box and the filter button. Place types live in the filter sheet.
/// The filter button is soft blue, solid with a count while filters are on,
/// and a clear (x) while typing. The solid translucent surface avoids a
/// per-frame backdrop blur while the list moves underneath it. Folding the
/// dock away on scroll (and the tab bar with it) is handled by the screen.
class ExploreFieldGuideDock extends StatefulWidget {
  const ExploreFieldGuideDock({
    super.key,
    required this.mode,
    required this.filterCount,
    required this.query,
    required this.onSearchChanged,
    required this.onFilterTap,
  });

  final ExploreViewMode mode;
  final int filterCount;
  final String query;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;

  @override
  State<ExploreFieldGuideDock> createState() => _ExploreFieldGuideDockState();
}

class _ExploreFieldGuideDockState extends State<ExploreFieldGuideDock> {
  late final _controller = TextEditingController(text: widget.query);

  @override
  void didUpdateWidget(ExploreFieldGuideDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final typing = widget.query.trim().isNotEmpty;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.exploreDockTint, Color(0xF2FFFFFF)],
          ),
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: ExploreDockSearchBox(
                  controller: _controller,
                  hint: widget.mode == ExploreViewMode.places
                      ? 'Search places or counties'
                      : 'Search counties',
                  onChanged: widget.onSearchChanged,
                ),
              ),
              if (widget.mode == ExploreViewMode.places || typing) ...[
                const SizedBox(width: 8),
                ExploreDockFilterButton(
                  mode: widget.mode,
                  typing: typing,
                  filterCount: widget.filterCount,
                  onFilter: widget.onFilterTap,
                  onClear: _clearSearch,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
