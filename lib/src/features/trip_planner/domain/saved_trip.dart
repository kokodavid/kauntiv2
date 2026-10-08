/// A trip plan a user saved: a destination and the stops planned on the way.
/// Only the plan is kept; the route is worked out again from wherever the
/// user is when it is opened.
class SavedTrip {
  const SavedTrip({
    required this.id,
    required this.name,
    required this.destinationPlaceId,
    required this.stopPlaceIds,
    required this.customOrder,
  });

  static const maxNameLength = 80;

  final String id;
  final String name;
  final String destinationPlaceId;

  /// Sorted when [customOrder] is false (the planner picks the driving
  /// order), else in the order the user chose.
  final List<String> stopPlaceIds;
  final bool customOrder;

  /// Same value as the planner's route key for these stops, so a saved plan
  /// can be matched with what is on screen.
  String get key => keyFor(stopPlaceIds, custom: customOrder);

  /// The planner's route key: sorted ids, or "!" and the ids in the user's
  /// order.
  static String keyFor(List<String> ids, {bool custom = false}) =>
      custom ? '!${ids.join(',')}' : ([...ids]..sort()).join(',');

  /// "Ol Donyo Sabuk", or "Ol Donyo Sabuk + 2 stops".
  static String suggestName(String placeName, int stops) {
    final suffix = stops == 0 ? '' : ' + $stops ${stops == 1 ? 'stop' : 'stops'}';
    final room = maxNameLength - suffix.length;
    final base = placeName.length > room
        ? placeName.substring(0, room).trimRight()
        : placeName;
    return '$base$suffix';
  }

  static SavedTrip? fromRow(Map<String, dynamic> row) {
    final id = row['id'];
    final name = row['name'];
    final destination = row['destination_place_id'];
    if (id is! String || name is! String || destination is! String) {
      return null;
    }
    final stops = row['stop_place_ids'];
    return SavedTrip(
      id: id,
      name: name,
      destinationPlaceId: destination,
      stopPlaceIds: [if (stops is List) ...stops.whereType<String>()],
      customOrder: row['custom_order'] == true,
    );
  }
}

/// The same plan is already saved.
class SavedTripExists implements Exception {
  const SavedTripExists();
}

/// The user is at the limit of saved trips.
class SavedTripsFull implements Exception {
  const SavedTripsFull();
}
