import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/plan_places_providers.dart';
import '../domain/plan_place.dart';
import '../domain/plan_place_query.dart';
import 'add_places_filters.dart';
import 'add_places_parts.dart';

/// Adds [place] to the plan; true when it was added.
typedef AddPlanPlace = Future<bool> Function(PlanPlace place);

/// Opens the Add places page. With [onAdd] it stays open so several places
/// can be added; without it, tapping a place closes the page and returns it
/// (used to choose where a plan starts).
Future<PlanPlace?> showAddPlacesPage(
  BuildContext context, {
  required String title,
  AddPlanPlace? onAdd,
  Set<String> alreadyIn = const {},
}) => Navigator.of(context).push<PlanPlace>(
  MaterialPageRoute(
    builder: (_) =>
        AddPlacesPage(title: title, onAdd: onAdd, alreadyIn: alreadyIn),
  ),
);

/// Add places (design 4a to 4c): search by name, browse by county, narrow
/// by type.
class AddPlacesPage extends ConsumerStatefulWidget {
  const AddPlacesPage({
    super.key,
    required this.title,
    this.onAdd,
    this.alreadyIn = const {},
  });

  final String title;
  final AddPlanPlace? onAdd;
  final Set<String> alreadyIn;

  @override
  ConsumerState<AddPlacesPage> createState() => _AddPlacesPageState();
}

class _AddPlacesPageState extends ConsumerState<AddPlacesPage> {
  final _text = TextEditingController();
  Timer? _debounce;
  PlanPlaceQuery _query = const PlanPlaceQuery();
  late final Set<String> _added = {...widget.alreadyIn};
  final _adding = <String>{};

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _typed(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(
          () => _query = PlanPlaceQuery(
            text: value,
            countyCode: _query.countyCode,
            type: _query.type,
          ),
        );
      }
    });
  }

  void _showMore() => setState(
    () => _query = PlanPlaceQuery(
      text: _query.text,
      countyCode: _query.countyCode,
      type: _query.type,
      limit: _query.limit + PlanPlaceQuery.pageSize,
    ),
  );

  void _refine({
    int? county,
    bool clearCounty = false,
    String? type,
    bool clearType = false,
  }) {
    setState(
      () => _query = PlanPlaceQuery(
        text: _text.text,
        countyCode: clearCounty ? null : county ?? _query.countyCode,
        type: clearType ? null : type ?? _query.type,
      ),
    );
  }

  Future<void> _pickCounty() async {
    final code = await showCountyFilterSheet(
      context,
      selected: _query.countyCode,
      only: ref.read(planPlaceFacetsProvider).value?.counties,
    );
    if (code == null) return;
    _refine(county: code == 0 ? null : code, clearCounty: code == 0);
  }

  Future<void> _add(PlanPlace place) async {
    final onAdd = widget.onAdd;
    if (onAdd == null) {
      Navigator.of(context).pop(place);
      return;
    }
    if (_added.contains(place.id) || !_adding.add(place.id)) return;
    setState(() {});
    final ok = await onAdd(place);
    _adding.remove(place.id);
    if (!mounted) return;
    setState(() {
      if (ok) _added.add(place.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(planPlaceSearchProvider(_query));
    // Until it is known (or if it can't be read) every filter is offered.
    final facets = ref.watch(planPlaceFacetsProvider).value;
    final countyName = _query.countyCode == null
        ? 'County'
        : CountyPaths.byCode[_query.countyCode]?.name ?? 'County';
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: AppBackButton(
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
        title: Text(widget.title, style: AppTypeScale.sectionTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: AppSearchField(
              controller: _text,
              onChanged: _typed,
              hint: 'Search places',
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                PlaceFilterChip(
                  label: 'All',
                  selected: _query.countyCode == null && _query.type == null,
                  onTap: () => _refine(clearCounty: true, clearType: true),
                ),
                if (facets == null ||
                    facets.counties.isNotEmpty ||
                    _query.countyCode != null)
                  PlaceFilterChip(
                    label: countyName,
                    icon: Icons.map_outlined,
                    selected: _query.countyCode != null,
                    onTap: () => unawaited(_pickCounty()),
                  ),
                for (final choice in placeTypeChoices(only: facets?.types))
                  PlaceFilterChip(
                    label: choice.label,
                    selected: _query.type == choice.key,
                    onTap: () => _query.type == choice.key
                        ? _refine(clearType: true)
                        : _refine(type: choice.key),
                  ),
              ],
            ),
          ),
          Expanded(child: _body(results)),
        ],
      ),
    );
  }

  Widget _body(AsyncValue<List<PlanPlace>> results) {
    if (results.hasError && !results.hasValue) {
      return AddPlacesNote(
        "Couldn't load places. Check your connection.",
        onRetry: () => ref.invalidate(planPlaceSearchProvider(_query)),
      );
    }
    final places = results.value;
    if (places == null) {
      return const Center(child: AppProgressIndicator());
    }
    if (places.isEmpty) return const AddPlacesNote('No places match. Try fewer words.');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: places.length + (places.length >= _query.limit ? 1 : 0),
      itemBuilder: (context, i) => i == places.length
          ? Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  textStyle: AppTypeScale.action,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: _showMore,
                child: const Text('Show more'),
              ),
            )
          : AddPlacesRow(
              place: places[i],
              added: _added.contains(places[i].id),
              adding: _adding.contains(places[i].id),
              pickOnly: widget.onAdd == null,
              onTap: () => unawaited(_add(places[i])),
            ),
    );
  }
}
