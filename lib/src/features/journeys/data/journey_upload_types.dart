import '../domain/journey_destination.dart';
import '../domain/journey_point.dart';
import '../domain/journey_quality.dart';
import '../domain/journey_transport_mode.dart';

/// Uploads one completed Journey; resolves once the server has stored it.
typedef UploadJourney =
    Future<void> Function({
      required String userId,
      required String id,
      required String title,
      required DateTime startedAt,
      required DateTime endedAt,
      required Duration pausedDuration,
      required List<JourneyPoint> points,
      JourneyDestination? destination,
      JourneyTransportMode? transportMode,
    });

/// Sends how well a Trip recorded, after the Trip itself has uploaded.
typedef SaveJourneyQuality =
    Future<void> Function({
      required String id,
      required JourneyQuality quality,
    });
