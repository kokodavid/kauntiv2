/// What the places list actually holds: the types and counties that have at
/// least one place, so Add places only offers filters that show something.
class PlanPlaceFacets {
  const PlanPlaceFacets({this.types = const {}, this.counties = const {}});

  final Set<String> types;
  final Set<int> counties;
}
