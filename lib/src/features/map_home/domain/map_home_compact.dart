import '../../../counties/county_paths.dart';
import 'map_home_layout.dart';
import 'map_home_models.dart';

/// What the collapsed sheet shows: one target, one button and a progress
/// line, all from data Home already has.
class MapHomeCompact {
  const MapHomeCompact({
    required this.context,
    required this.title,
    required this.meta,
    required this.county,
    required this.suggestion,
    required this.progress,
    this.imageUrl,
    this.isHomeStart = false,
  });

  /// The small caps line: "NEXT BEST MOVE", "NEAREST UNCLAIMED", "START HERE".
  final String context;
  final String title;
  final String meta;
  final CountyPath county;
  final MapHomeSuggestion suggestion;
  final String progress;
  final String? imageUrl;

  /// The new-user card: its button starts a Trip when one can be started.
  final bool isHomeStart;

  /// "12 of 47 claimed · Explorer · 35 to go". The tier is left out until
  /// the first medal is earned.
  static String progressLine(MapHomeBoardData data) {
    final claimed = data.exploredCount;
    final total = data.totalCounties;
    final tier = data.tier;
    final left = total - claimed;
    return [
      '$claimed of $total claimed',
      ?tier?.label,
      if (left > 0) '$left to go',
    ].join(' · ');
  }

  static String _distance(String label) => label.replaceFirst(' away', '');

  /// The collapsed card for [layout], or null when there is nothing to
  /// point at (no suggestion, no unclaimed county, no home county).
  static MapHomeCompact? forLayout(
    MapHomeLayout layout,
    MapHomeBoardData data,
  ) {
    final progress = progressLine(data);
    if (layout == MapHomeLayout.newUser) {
      final home = data.homeCountySuggestion;
      if (home != null) {
        return MapHomeCompact(
          context: 'START HERE',
          title: 'Claim ${home.county.name}, your home county',
          meta: 'Record a trip inside ${home.county.name} to claim it.',
          county: home.county,
          suggestion: home,
          progress: progress,
          imageUrl: home.highlightImageUrl,
          isHomeStart: true,
        );
      }
    }
    final nearest = data.unclaimed.firstOrNull;
    final suggestion =
        layout == MapHomeLayout.recording || layout == MapHomeLayout.claim
        ? nearest ?? data.fallbackTop
        : data.fallbackTop ?? nearest;
    if (suggestion == null) return null;
    final context = switch (layout) {
      MapHomeLayout.recording => 'NEAREST UNCLAIMED',
      MapHomeLayout.claim => 'NEXT GOAL',
      _ => 'NEXT BEST MOVE',
    };
    return MapHomeCompact(
      context: context,
      title:
          '${suggestion.county.name} · ${_distance(suggestion.distanceAway)}',
      meta: suggestion.placeName ?? suggestion.reasonLabel,
      county: suggestion.county,
      suggestion: suggestion,
      progress: progress,
      imageUrl: suggestion.highlightImageUrl,
    );
  }
}
