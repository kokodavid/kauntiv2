/// Whether Explore's category pills show how many places they hold.
///
/// Off for now: Explore loads only a few preview places per county, so the
/// numbers undercount the catalogue and would tell travellers the platform
/// has fewer places than it does. Turn this back on once the board counts
/// every place (or the catalogue is large enough that a count helps).
const exploreShowsPillCounts = false;

/// "Waterfalls · 4" when counts are shown, otherwise just "Waterfalls".
String explorePillLabel(String label, int count) =>
    exploreShowsPillCounts ? '$label · $count' : label;
