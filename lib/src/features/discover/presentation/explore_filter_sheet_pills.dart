import 'package:flutter/material.dart';

import '../../../core/widgets/place_type_style.dart';
import '../../profile/domain/place_interest.dart';
import 'explore_dock_types.dart';
import 'explore_filter_sheet_parts.dart';
import 'explore_pill_counts.dart';

/// The sheet's TYPE section: "All" plus one pill per place type that has
/// places, the traveller's interest types first. Any number can be on;
/// "All" clears them. Only the first [collapsedCount] types show until
/// "Show all" is tapped, and a picked type is never left hidden.
class ExploreTypePills extends StatefulWidget {
  const ExploreTypePills({
    super.key,
    required this.types,
    required this.totalCount,
    required this.selectedKeys,
    required this.onToggle,
    this.collapsedCount = 8,
  });

  final List<ExploreDockType> types;
  final int totalCount;
  final Set<String> selectedKeys;
  final int collapsedCount;

  /// A type key to switch on or off, or null for "All".
  final ValueChanged<String?> onToggle;

  @override
  State<ExploreTypePills> createState() => _ExploreTypePillsState();
}

class _ExploreTypePillsState extends State<ExploreTypePills> {
  late bool _expanded = _hidesSelected;

  bool get _hidesSelected => widget.types
      .skip(widget.collapsedCount)
      .any((item) => widget.selectedKeys.contains(item.type.key));

  @override
  void didUpdateWidget(ExploreTypePills oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Picking a hidden type (through an interest, say) opens the list.
    if (_hidesSelected) _expanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final overflow = widget.types.length > widget.collapsedCount;
    final shown = _expanded || !overflow
        ? widget.types
        : widget.types.take(widget.collapsedCount).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ExploreWherePill(
          label: explorePillLabel('All', widget.totalCount),
          icon: Icons.apps_rounded,
          selected: widget.selectedKeys.isEmpty,
          onTap: () => widget.onToggle(null),
        ),
        for (final item in shown)
          ExploreWherePill(
            label: explorePillLabel(item.type.pluralLabel, item.count),
            icon: item.type.icon,
            selected: widget.selectedKeys.contains(item.type.key),
            onTap: () => widget.onToggle(item.type.key),
          ),
        if (overflow)
          ExploreWherePill(
            label: _expanded ? 'Show less' : 'Show all ${widget.types.length}',
            icon: _expanded
                ? Icons.expand_less_rounded
                : Icons.expand_more_rounded,
            selected: false,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
      ],
    );
  }
}

/// The sheet's FOR YOU pills: the traveller's interests, each standing for a
/// group of types. An interest is on when all its types are on.
class ExploreInterestPills extends StatelessWidget {
  const ExploreInterestPills({
    super.key,
    required this.interestTypes,
    required this.on,
    required this.onToggle,
  });

  final Map<PlaceInterest, Set<String>> interestTypes;
  final Set<String> on;
  final ValueChanged<PlaceInterest> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in interestTypes.entries)
          ExploreWherePill(
            label: entry.key.label,
            selected: on.containsAll(entry.value),
            onTap: () => onToggle(entry.key),
          ),
      ],
    );
  }
}
