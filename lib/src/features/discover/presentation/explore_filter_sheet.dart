import 'package:flutter/material.dart';

import '../../../core/widgets/county_badge_medallion.dart';
import '../../../counties/county_paths.dart';
import '../../../widgets/county_picker_sheet.dart';
import '../../profile/domain/place_interest.dart';
import '../domain/explore_filters.dart';
import '../domain/explore_results.dart';
import 'explore_dock_types.dart';
import 'explore_filter_sheet_frame.dart';
import 'explore_filter_sheet_parts.dart';
import 'explore_filter_sheet_pills.dart';

/// The Places filter sheet (design frame 2b): place type, interests,
/// distance, county and claim state, with a button that shows the live
/// result count. Returns the new filters, or null when dismissed.
Future<ExploreFilters?> showExploreFilterSheet(
  BuildContext context, {
  required ExploreFilters initial,
  required bool hasLocation,
  required int unclaimedCountyCount,
  required int Function(ExploreFilters filters) countFor,
  Map<PlaceInterest, Set<String>> interestTypes = const {},
  List<ExploreDockType> types = const [],
  int totalCount = 0,
  VoidCallback? onChooseInterests,
}) => showModalBottomSheet<ExploreFilters>(
  context: context,
  isScrollControlled: true,
  // A sheet, not a page: the handle and the scrim stay visible above it.
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.85,
  ),
  // The root navigator, so the sheet covers the floating tab bar.
  useRootNavigator: true,
  backgroundColor: Colors.white,
  barrierColor: const Color(0x6609090B),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (context) => _ExploreFilterSheet(
    initial: initial,
    hasLocation: hasLocation,
    unclaimedCountyCount: unclaimedCountyCount,
    countFor: countFor,
    interestTypes: interestTypes,
    types: types,
    totalCount: totalCount,
    onChooseInterests: onChooseInterests,
  ),
);

class _ExploreFilterSheet extends StatefulWidget {
  const _ExploreFilterSheet({
    required this.initial,
    required this.hasLocation,
    required this.unclaimedCountyCount,
    required this.countFor,
    required this.interestTypes,
    required this.types,
    required this.totalCount,
    this.onChooseInterests,
  });

  final ExploreFilters initial;
  final bool hasLocation;
  final int unclaimedCountyCount;
  final int Function(ExploreFilters filters) countFor;
  final Map<PlaceInterest, Set<String>> interestTypes;
  final List<ExploreDockType> types;
  final int totalCount;

  /// Set when the traveller has no interests: shows a prompt in place of
  /// the FOR YOU row that closes the sheet and opens the picker.
  final VoidCallback? onChooseInterests;

  @override
  State<_ExploreFilterSheet> createState() => _ExploreFilterSheetState();
}

class _ExploreFilterSheetState extends State<_ExploreFilterSheet> {
  late ExploreFilters _filters = widget.initial;

  static const _stops = ExploreFilters.distanceStops;

  int get _stopIndex {
    final limit = _filters.maxKm;
    if (limit == null) return _stops.length;
    final index = _stops.indexOf(limit);
    return index == -1 ? _stops.length : index;
  }

  void _setTypes(Set<String> on) =>
      setState(() => _filters = _filters.withTypes(on));

  void _toggleType(String? key) {
    final on = {..._filters.activeTypes};
    if (key == null) {
      on.clear();
    } else if (!on.remove(key)) {
      on.add(key);
    }
    _setTypes(on);
  }

  /// An interest adds or removes its whole group of types.
  void _toggleInterest(PlaceInterest interest) {
    final types = widget.interestTypes[interest]!;
    final on = {..._filters.activeTypes};
    if (on.containsAll(types)) {
      on.removeAll(types);
    } else {
      on.addAll(types);
    }
    _setTypes(on);
  }

  void _reset() => setState(() => _filters = const ExploreFilters.none());

  Future<void> _pickCounty() async {
    final picked = await CountyPickerSheet.show(
      context,
      selectedCounty: _filters.countyCode == null
          ? null
          : CountyPaths.byCode[_filters.countyCode!],
    );
    if (!mounted || picked == null) return;
    setState(() => _filters = _filters.copyWith(countyCode: picked.code));
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.countFor(_filters);
    final noun = exploreNoun(_filters.typeKey, count);
    final county = _filters.countyCode == null
        ? null
        : CountyPaths.byCode[_filters.countyCode!];
    final sample = CountyPaths.all.firstWhere(
      (c) => c.name == 'Nyeri',
      orElse: () => CountyPaths.all.first,
    );
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExploreSheetHeader(onReset: _reset),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.types.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('TYPE', style: exploreSheetLabel),
                    const SizedBox(height: 10),
                    ExploreTypePills(
                      types: widget.types,
                      totalCount: widget.totalCount,
                      selectedKeys: _filters.activeTypes,
                      onToggle: _toggleType,
                    ),
                  ],
                  if (widget.interestTypes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('FOR YOU', style: exploreSheetLabel),
                    const SizedBox(height: 10),
                    ExploreInterestPills(
                      interestTypes: widget.interestTypes,
                      on: _filters.activeTypes,
                      onToggle: _toggleInterest,
                    ),
                  ],
                  if (widget.onChooseInterests case final choose?) ...[
                    const SizedBox(height: 20),
                    const Text('FOR YOU', style: exploreSheetLabel),
                    const SizedBox(height: 8),
                    ExploreChooseInterests(
                      onTap: () {
                        Navigator.of(context).pop();
                        choose();
                      },
                    ),
                  ],
                  if (widget.hasLocation) ...[
                    const SizedBox(height: 20),
                    ExploreDistanceBlock(
                      index: _stopIndex,
                      onChanged: (index) => setState(
                        () => _filters = index >= _stops.length
                            ? _filters.copyWith(clearMaxKm: true)
                            : _filters.copyWith(maxKm: _stops[index]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text('WHERE', style: exploreSheetLabel),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ExploreWherePill(
                        label: 'Anywhere',
                        selected: county == null,
                        onTap: () => setState(
                          () => _filters = _filters.copyWith(clearCounty: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ExploreWherePill(
                        label: county?.name ?? 'A county',
                        selected: county != null,
                        chevron: true,
                        onTap: _pickCounty,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (widget.unclaimedCountyCount > 0)
                    ExploreToggleRow(
                      leading: CountyBadgeMedallion(
                        county: sample,
                        earned: false,
                        size: 24,
                      ),
                      title: "Only counties I haven't claimed",
                      subtitle: '${widget.unclaimedCountyCount} counties',
                      value: _filters.unclaimedOnly,
                      onChanged: (value) => setState(
                        () =>
                            _filters = _filters.copyWith(unclaimedOnly: value),
                      ),
                    ),
                ],
              ),
            ),
          ),
          ExploreSheetFooter(
            label: count == 0 ? 'No $noun match' : 'Show $count $noun',
            onPressed: count == 0
                ? null
                : () => Navigator.of(context).pop(_filters),
          ),
        ],
      ),
    );
  }
}
