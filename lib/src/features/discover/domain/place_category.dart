/// A place's category as shown on detail pages and place cards.
enum PlaceCategory {
  park('Park'),
  shore('Shore'),
  heritage('Heritage'),
  culture('Culture'),
  stay('Stay'),
  eat('Eat');

  const PlaceCategory(this.label);

  final String label;

  /// Maps a `places.type` value. Museums read as heritage (v1 parity);
  /// anything unknown falls back to culture.
  static PlaceCategory fromType(String type) => switch (type) {
    'park' => park,
    'shore' => shore,
    'heritage' || 'museum' => heritage,
    'culture' => culture,
    'stay' => stay,
    'eat' => eat,
    _ => culture,
  };
}
