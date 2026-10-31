import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/plan_place_search.dart';
import '../domain/plan_place_suggestion.dart';
import '../domain/trip_plan.dart';

/// Opens the start-point search. Returns the chosen spot as a plan start,
/// or null when the user backs out.
Future<PlanStart?> showStartSearchPage(
  BuildContext context, {
  String title = 'Start from a place',
}) => Navigator.of(context).push<PlanStart>(
  MaterialPageRoute(builder: (_) => StartSearchPage(title: title)),
);

/// Where does Day 1 start? A search box that suggests real places (an
/// address, a business, a landmark, a town) as the user types.
class StartSearchPage extends ConsumerStatefulWidget {
  const StartSearchPage({super.key, this.title = 'Start from a place'});

  final String title;

  @override
  ConsumerState<StartSearchPage> createState() => _StartSearchPageState();
}

class _StartSearchPageState extends ConsumerState<StartSearchPage> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _text.text.trim();
    final ready = query.length >= planPlaceSearchMinLength;
    final results = ready ? ref.watch(planPlaceSuggestionsProvider(query)) : null;
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
              autofocus: true,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search an address, landmark or town',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _text.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(_text.clear),
                      ),
                filled: true,
                fillColor: AppColors.exploreSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _body(query, results)),
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Search by Geoapify · © OpenStreetMap contributors',
                style: AppTypeScale.meta,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(String query, AsyncValue<List<PlanPlaceSuggestion>>? results) {
    if (results == null) {
      return const _Note(
        'Type at least 3 letters. The more exact, the better the spot: '
        'a street, a shop, a gate or a stage.',
      );
    }
    if (results.hasError && !results.hasValue) {
      return _Note(
        "Couldn't search. Check your connection.",
        onRetry: () => ref.invalidate(planPlaceSuggestionsProvider(query)),
      );
    }
    final found = results.value;
    if (found == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (found.isEmpty) {
      return const _Note(
        'No match. Try the street or the nearest landmark or town.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: found.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.softDivider),
      itemBuilder: (context, i) => _Suggestion(
        suggestion: found[i],
        onTap: () => Navigator.of(context).pop(found[i].toStart()),
      ),
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.suggestion, required this.onTap});

  final PlanPlaceSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.place_outlined,
              size: 20,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypeScale.itemTitle,
                  ),
                  if (suggestion.address != null)
                    Text(
                      suggestion.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypeScale.small,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.message, {this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center, style: AppTypeScale.body),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
