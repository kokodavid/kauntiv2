import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../application/plan_places_providers.dart';
import '../domain/plan_place.dart';
import '../domain/plan_place_query.dart';
import 'add_places_filters.dart';
import 'plan_place_thumb.dart';
import 'plan_stop_row.dart';

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

  void _refine({int? county, bool clearCounty = false, String? type, bool clearType = false}) {
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
    final countyName = _query.countyCode == null
        ? 'County'
        : CountyPaths.byCode[_query.countyCode]?.name ?? 'County';
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        elevation: 0,
        title: Text(widget.title, style: AppTypeScale.sectionTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _text,
              onChanged: _typed,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search places',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.exploreSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                PlaceFilterChip(
                  label: countyName,
                  icon: Icons.map_outlined,
                  selected: _query.countyCode != null,
                  onTap: () => unawaited(_pickCounty()),
                ),
                for (final choice in placeTypeChoices())
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
    if (!_query.isReady) {
      return const _Note('Search by name, or pick a county or a type.');
    }
    if (results.hasError && !results.hasValue) {
      return _Note(
        "Couldn't load places. Check your connection.",
        onRetry: () => ref.invalidate(planPlaceSearchProvider(_query)),
      );
    }
    final places = results.value;
    if (places == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (places.isEmpty) return const _Note('No places match. Try fewer words.');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: places.length,
      itemBuilder: (context, i) => _Row(
        place: places[i],
        added: _added.contains(places[i].id),
        adding: _adding.contains(places[i].id),
        pickOnly: widget.onAdd == null,
        onTap: () => unawaited(_add(places[i])),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.place,
    required this.added,
    required this.adding,
    required this.pickOnly,
    required this.onTap,
  });

  final PlanPlace place;
  final bool added;
  final bool adding;
  final bool pickOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: added ? '${place.name}, added' : 'Add ${place.name}',
    child: InkWell(
      onTap: added ? null : onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Row(
          children: [
            PlanPlaceThumb(url: place.thumbnailUrl, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: AppTypeScale.itemTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    planPlaceMeta(place.type, place.countyCode),
                    style: AppTypeScale.meta,
                  ),
                ],
              ),
            ),
            if (!pickOnly)
              SizedBox(
                width: 44,
                height: 44,
                child: adding
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        added ? Icons.check_circle : Icons.add_circle_outline,
                        color: added
                            ? AppColors.legendHome
                            : AppColors.accent,
                      ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text, {this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center, style: AppTypeScale.small),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
