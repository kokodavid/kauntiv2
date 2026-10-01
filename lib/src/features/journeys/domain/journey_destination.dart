/// A place chosen before recording. The snapshot stays useful if the place
/// listing changes or is removed later.
class JourneyDestination {
  const JourneyDestination({
    required this.placeId,
    required this.name,
    this.latitude,
    this.longitude,
  });

  final String placeId;
  final String name;
  final double? latitude;
  final double? longitude;

  bool get isValid =>
      placeId.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      name.trim().length <= 160 &&
      ((latitude == null && longitude == null) ||
          (latitude != null &&
              longitude != null &&
              latitude!.isFinite &&
              longitude!.isFinite &&
              latitude! >= -90 &&
              latitude! <= 90 &&
              longitude! >= -180 &&
              longitude! <= 180));
}
