/// Which stats a shared Trip image shows. Hidden stats are left out of the
/// rendered image entirely (the card drops them, it doesn't blur them).
///
/// FB-005 decision: top speed starts hidden, everything else starts shown.
class TripShareStatVisibility {
  const TripShareStatVisibility({
    this.distance = true,
    this.topSpeed = true,
    this.averageSpeed = true,
    this.elevation = true,
  });

  /// Every stat shown - what the in-app history thumbnail always uses.
  static const all = TripShareStatVisibility();

  /// The share sheet's starting choice: top speed off, the rest on.
  static const sharingDefault = TripShareStatVisibility(topSpeed: false);

  final bool distance;
  final bool topSpeed;
  final bool averageSpeed;
  final bool elevation;

  TripShareStatVisibility copyWith({
    bool? distance,
    bool? topSpeed,
    bool? averageSpeed,
    bool? elevation,
  }) => TripShareStatVisibility(
    distance: distance ?? this.distance,
    topSpeed: topSpeed ?? this.topSpeed,
    averageSpeed: averageSpeed ?? this.averageSpeed,
    elevation: elevation ?? this.elevation,
  );

  @override
  bool operator ==(Object other) =>
      other is TripShareStatVisibility &&
      other.distance == distance &&
      other.topSpeed == topSpeed &&
      other.averageSpeed == averageSpeed &&
      other.elevation == elevation;

  @override
  int get hashCode => Object.hash(distance, topSpeed, averageSpeed, elevation);
}
