import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../../../widgets/county_picker_sheet.dart';
import '../application/plan_places_providers.dart';
import '../domain/custom_place_draft.dart';
import '../domain/plan_place.dart';
import '../domain/plan_place_query.dart';
import 'add_places_filters.dart';
import 'add_places_outside.dart';
import 'add_places_parts.dart';
import 'drop_pin_page.dart';

/// Adds [place] to the plan; true when it was added.
typedef AddPlanPlace = Future<bool> Function(PlanPlace place);

/// Adds a place from outside Kaunti47 to the plan; true when it was added.
typedef AddCustomPlace = Future<bool> Function(CustomPlaceDraft place);

/// Opens the Add places page. With [onAdd] it stays open so several places
/// can be added; without it, tapping a place closes the page and returns it
/// (used to choose where a plan starts).
Future<PlanPlace?> showAddPlacesPage(
  BuildContext context, {
  required String title,
  AddPlanPlace? onAdd,
  AddCustomPlace? onAddCustom,
  Set<String> alreadyIn = const {},
}) => Navigator.of(context).push<PlanPlace>(
  MaterialPageRoute(
    builder: (_) => AddPlacesPage(
      title: title,
      onAdd: onAdd,
      onAddCustom: onAddCustom,
      alreadyIn: alreadyIn,
    ),
  ),
);

/// Add places (design 4a to 4c): search by name, browse by county, narrow
/// by type.
class AddPlacesPage extends ConsumerStatefulWidget {
  const AddPlacesPage({
    super.key,
    required this.title,
    this.onAdd,
    this.onAddCustom,
    this.alreadyIn = const {},
  });

  final String title;
  final AddPlanPlace? onAdd;

  /// When set, the page also offers places from outside Kaunti47.
  final AddCustomPlace? onAddCustom;
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
  bool _searchOutside = false;

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
          () {
            _searchOutside = false;
            _query = PlanPlaceQuery(
            text: value,
            countyCode: _query.countyCode,
            type: _query.type,
          );
          },
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
    final county = await CountyPickerSheet.show(
      context,
      selectedCounty: CountyPaths.byCode[_query.countyCode],
      onlyCodes: ref.read(planPlaceFacetsProvider).value?.counties,
      title: 'Browse by county',
    );
    if (county != null) _refine(county: county.code);
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

  Future<void> _addCustom(CustomPlaceDraft draft) async {
    final onAddCustom = widget.onAddCustom;
    if (onAddCustom == null || _added.contains(draft.key)) return;
    if (!_adding.add(draft.key)) return;
    setState(() {});
    final ok = await onAddCustom(draft);
    _adding.remove(draft.key);
    if (!mounted) return;
    setState(() {
      if (ok) _added.add(draft.key);
    });
  }

  Future<void> _dropPin() async {
    final draft = await showDropPinPage(context);
    if (draft == null || !mounted) return;
    await _addCustom(draft);
    if (!mounted || !_added.contains(draft.key)) return;
    showAppToast(
      context,
      variant: AppToastVariant.neutral,
      title: '${draft.name} added',
    );
  }

  Widget? _outside() {
    if (widget.onAddCustom == null) return null;
    return AddPlacesOutside(
      text: _text.text,
      searching: _searchOutside,
      added: _added,
      adding: _adding,
      onSearch: () => setState(() => _searchOutside = true),
      onPick: (draft) => unawaited(_addCustom(draft)),
      onPin: () => unawaited(_dropPin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(planPlaceSearchProvider(_query));
    // Until it is known (or if it can't be read) every filter is offered.
    final facets = ref.watch(planPlaceFacetsProvider).value;
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
          AddPlacesFilterBar(
            query: _query,
            facets: facets,
            onAll: () => _refine(clearCounty: true, clearType: true),
            onCounty: () => unawaited(_pickCounty()),
            onType: (key) => _query.type == key
                ? _refine(clearType: true)
                : _refine(type: key),
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
    final outside = _outside();
    if (places.isEmpty) {
      return outside == null
          ? const AddPlacesNote('No places match. Try fewer words.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: [
                const Text(
                  'No places in Kaunti47 match.',
                  textAlign: TextAlign.center,
                  style: AppTypeScale.small,
                ),
                outside,
              ],
            );
    }
    final more = places.length >= _query.limit;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: places.length + (more ? 1 : 0) + (outside == null ? 0 : 1),
      itemBuilder: (context, i) {
        if (i < places.length) {
          return AddPlacesRow(
            place: places[i],
            added: _added.contains(places[i].id),
            adding: _adding.contains(places[i].id),
            pickOnly: widget.onAdd == null,
            onTap: () => unawaited(_add(places[i])),
          );
        }
        if (more && i == places.length) {
          return Center(
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                textStyle: AppTypeScale.action,
                minimumSize: const Size(44, 44),
              ),
              onPressed: _showMore,
              child: const Text('Show more'),
            ),
          );
        }
        return outside!;
      },
    );
  }
}
