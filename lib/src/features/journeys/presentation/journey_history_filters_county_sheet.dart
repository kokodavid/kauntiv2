part of 'journey_history_filters.dart';

/// The county picker sheet itself: a header ("Counties" / "You've been to
/// N of 47"), one row per county with its code, name, Trip count and a
/// check mark, and a sticky "Show N trips" button that confirms the pick
/// (any number of counties, or none) rather than applying on tap. A Trip
/// shows if it crossed at least one of the checked counties.
class _CountySheet extends StatefulWidget {
  const _CountySheet({
    required this.counties,
    required this.countTripsFor,
    required this.current,
  });

  final List<JourneyCountyOption> counties;
  final int Function(Set<String> counties) countTripsFor;
  final Set<String> current;

  @override
  State<_CountySheet> createState() => _CountySheetState();
}
