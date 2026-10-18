import 'package:flutter/material.dart';

import '../domain/explore_entries.dart';
import 'explore_chapter_header.dart';
import 'explore_field_place_card.dart';
import 'explore_place_row.dart';
import 'explore_styles.dart';

/// A card's width and the gap after it; the row scrolls in steps of both.
const _cardWidth = 240.0;
const _cardGap = 10.0;

/// One Places chapter: header, an optional lead card, then a row of cards.
class ExploreChapter extends StatelessWidget {
  const ExploreChapter({
    super.key,
    required this.kicker,
    required this.title,
    required this.places,
    this.lead,
    this.action,
    this.onAction,
    this.onOpenPlace,
    this.showHeader = true,
  });

  final String kicker;
  final String title;
  final List<ExploreEntry> places;
  final ExploreEntry? lead;
  final String? action;
  final VoidCallback? onAction;
  final OpenExplorePlace? onOpenPlace;

  /// False for a chapter that is just its cards, with no kicker or title.
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          ExploreChapterHeader(
            kicker: kicker,
            title: title,
            action: onAction == null ? null : action,
            onAction: onAction,
          ),
          const SizedBox(height: 8),
        ],
        if (lead case final entry?) ...[
          ExploreFieldPlaceCard(
            place: entry.place,
            countyCode: entry.countyCode,
            claimed: entry.claimed,
            onOpen: onOpenPlace,
            width: double.infinity,
            height: 220,
          ),
          if (places.isNotEmpty) const SizedBox(height: 10),
        ],
        if (places.length == 1 && lead == null)
          // One card would leave an empty row beside it, so it takes the full
          // width, the same card the lead of a chapter uses.
          ExploreFieldPlaceCard(
            key: ValueKey(places.first.place.id),
            place: places.first.place,
            countyCode: places.first.countyCode,
            claimed: places.first.claimed,
            onOpen: onOpenPlace,
            width: double.infinity,
            height: 220,
          )
        else if (places.isNotEmpty)
          SizedBox(
            height: 300,
            // Built lazily: only the cards on (or just off) screen exist, so
            // a chapter scrolling into view does not decode every photo.
            child: ListView.builder(
              key: PageStorageKey<String>('explore-chapter-$title'),
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: EdgeInsets.zero,
              itemCount: places.length,
              itemExtent: _cardWidth + _cardGap,
              // Each card already paints in its own repaint boundary.
              addRepaintBoundaries: false,
              itemBuilder: (context, index) {
                final place = places[index];
                return Align(
                  alignment: Alignment.centerLeft,
                  child: ExploreFieldPlaceCard(
                    key: ValueKey(place.place.id),
                    place: place.place,
                    countyCode: place.countyCode,
                    claimed: place.claimed,
                    onOpen: onOpenPlace,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class ExplorePlacesEmptyState extends StatelessWidget {
  const ExplorePlacesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: ExploreStyles.cardDecoration,
      child: const Text(
        'Places will appear here as the guide grows.',
        style: ExploreStyles.emptyBody,
      ),
    );
  }
}
