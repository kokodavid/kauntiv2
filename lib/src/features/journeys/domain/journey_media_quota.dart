/// How many photos one Trip may hold for this account, as the server
/// reports it (25 free, 50 Pro - the numbers live in the database).
class JourneyMediaLimit {
  const JourneyMediaLimit({
    required this.maxPhotos,
    required this.isPro,
    required this.proMaxPhotos,
  });

  final int maxPhotos;
  final bool isPro;

  /// What upgrading would raise [maxPhotos] to, for the upgrade hint.
  final int proMaxPhotos;

  /// Photos still allowed on a Trip that already holds [used].
  int remaining(int used) => (maxPhotos - used).clamp(0, maxPhotos);

  bool isFull(int used) => used >= maxPhotos;

  /// "12 of 25".
  String usageLabel(int used) => '$used of $maxPhotos';

  /// Shown when a Trip can't take more photos.
  String get fullMessage => isPro
      ? 'This Trip has the most photos allowed ($maxPhotos). '
            'Remove one to add another.'
      : 'This Trip is full ($maxPhotos photos). Remove one, or upgrade to '
            'Pro for up to $proMaxPhotos.';
}

/// Splits [wanted] photos into those that fit and those that don't.
int photosThatFit(
  JourneyMediaLimit? limit, {
  required int used,
  required int wanted,
}) => limit == null ? wanted : wanted.clamp(0, limit.remaining(used));
