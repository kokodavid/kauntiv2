/// One photo of a place as the gallery shows it: the image and, for a
/// photo a user took, "@username" (null for the app's own photos).
class PlacePhotoItem {
  const PlacePhotoItem({required this.url, this.credit, this.aspect});

  final String url;
  final String? credit;

  /// Width / height when known.
  final double? aspect;

  bool get isUser => credit != null;

  /// The line under a photo in the gallery.
  String get creditLine => credit == null ? 'Kaunti47' : 'Photo by $credit';
}
