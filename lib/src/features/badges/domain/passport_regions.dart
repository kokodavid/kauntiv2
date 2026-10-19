/// The eight regions the Passport groups counties by, in display order:
/// alphabetical, so there is nothing to learn.
enum PassportRegion {
  central('Central'),
  coast('Coast'),
  eastern('Eastern'),
  nairobi('Nairobi'),
  northEastern('North Eastern'),
  nyanza('Nyanza'),
  riftValley('Rift Valley'),
  western('Western');

  const PassportRegion(this.label);

  final String label;

  /// The region of a county by its official code (1 Mombasa to 47 Nairobi).
  static PassportRegion of(int code) {
    if (code >= 1 && code <= 6) return coast;
    if (code >= 7 && code <= 9) return northEastern;
    if (code >= 10 && code <= 17) return eastern;
    if (code >= 18 && code <= 22) return central;
    if (code >= 23 && code <= 36) return riftValley;
    if (code >= 37 && code <= 40) return western;
    if (code >= 41 && code <= 46) return nyanza;
    return nairobi;
  }
}
