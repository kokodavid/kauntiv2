/// A public-trip request the server refused or that could not be made.
/// [message] is safe to show to the user.
class PublicTripFailure implements Exception {
  const PublicTripFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
