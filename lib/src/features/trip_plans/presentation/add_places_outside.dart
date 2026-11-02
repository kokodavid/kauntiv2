
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/counties/county_boundary_resolver.dart';
import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/plan_place_search.dart';
import '../domain/custom_place_draft.dart';
import '../domain/plan_place.dart';
import 'add_places_parts.dart';

/// The part of Add places for spots that aren't in Kaunti47: a search of the
/// wider map (run only when asked, to keep calls low) and a dropped pin.
class AddPlacesOutside extends ConsumerWidget {
  const AddPlacesOutside({
    super.key,
    required this.text,
    required this.searching,
    required this.added,
    required this.adding,
    required this.onSearch,
    required this.onPick,
    required this.onPin,
  });

  /// What was typed in the search box.
  final String text;

  /// Whether the user asked to search other places for [text].
  final bool searching;
  final Set<String> added;
  final Set<String> adding;
  final VoidCallback onSearch;
  final ValueChanged<CustomPlaceDraft> onPick;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = text.trim();
    final canSearch = query.length >= planPlaceSearchMinLength;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 16, 0, 4),
          child: Text('NOT IN KAUNTI47?', style: AppTypeScale.sectionLabel),
        ),
        if (canSearch && !searching)
          _ActionRow(
            icon: Icons.travel_explore,
            title: 'Search other places',
            detail: 'Look for “$query” on the wider map',
            onTap: onSearch,
          ),
        if (canSearch && searching) _results(ref, query),
        _ActionRow(
          icon: Icons.place_outlined,
          title: 'Drop a pin',
          detail: 'A stay, a home or anywhere without a listing',
          onTap: onPin,
        ),
      ],
    );
  }

  Widget _results(WidgetRef ref, String query) {
    final results = ref.watch(planPlaceSuggestionsProvider(query));
    if (results.hasError && !results.hasValue) {
      return AddPlacesNote(
        "Couldn't search. Check your connection.",
        onRetry: () => ref.invalidate(planPlaceSuggestionsProvider(query)),
      );
    }
    final found = results.value;
    if (found == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: AppProgressIndicator()),
      );
    }
    if (found.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No match. Try the street or the nearest town, or drop a pin.',
          style: AppTypeScale.small,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final suggestion in found)
          _result(
            CustomPlaceDraft.fromSuggestion(
              suggestion,
              countyCode: CountyBoundaryResolver.countyCodeFor(
                latitude: suggestion.lat,
                longitude: suggestion.lng,
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Search by Geoapify · © OpenStreetMap contributors',
            style: AppTypeScale.meta,
          ),
        ),
      ],
    );
  }

  Widget _result(CustomPlaceDraft draft) {
    final place = PlanPlace(
      id: draft.key,
      name: draft.name,
      type: '',
      countyCode: draft.countyCode ?? 0,
      lat: draft.lat,
      lng: draft.lng,
      isCustom: true,
      address: draft.address,
    );
    return AddPlacesRow(
      place: place,
      added: added.contains(draft.key),
      adding: adding.contains(draft.key),
      pickOnly: false,
      onTap: () => onPick(draft),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: title,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accentTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypeScale.itemTitle),
                  Text(
                    detail,
                    style: AppTypeScale.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    ),
  );
}
