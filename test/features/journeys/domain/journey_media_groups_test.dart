import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/data/trip_share_card_cache.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_media_capture.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_summary.dart';

JourneyMediaItem _item(String id, {required bool onTimeline, int minute = 0}) =>
    JourneyMediaItem(
      id: id,
      url: 'https://example.com/$id.jpg',
      capturedAt: DateTime.utc(2026, 9, 25, 10, minute),
      isTimelineMedia: onTimeline,
    );

JourneySummary _summary({String? coverMediaId}) => JourneySummary(
  id: 'j',
  title: 'Morning drive',
  startedAt: DateTime.utc(2026, 9, 25, 10),
  endedAt: DateTime.utc(2026, 9, 25, 11),
  isUploaded: true,
  coverMediaId: coverMediaId,
);

void main() {
  final album = _item('album', onTimeline: false, minute: 1);
  final taken = _item('taken', onTimeline: true, minute: 30);

  test('media splits into timeline photos and album-only photos', () {
    final media = [album, taken];
    expect(media.onTimeline.map((i) => i.id), ['taken']);
    expect(media.albumOnly.map((i) => i.id), ['album']);
  });

  test('a photo is timeline media unless it says otherwise', () {
    final plain = JourneyMediaItem(
      id: 'x',
      url: 'u',
      capturedAt: DateTime.utc(2026),
    );
    expect(plain.isTimelineMedia, isTrue);
    expect(
      JourneyMediaCapture(
        id: 'c',
        journeyId: 'j',
        localPath: '/p',
        capturedAt: DateTime.utc(2026),
      ).isTimelineMedia,
      isTrue,
    );
  });

  test('the default cover prefers a photo taken during the Trip', () {
    final cover = TripShareCardCache.resolveCoverPhoto(_summary(), [
      album,
      taken,
    ]);
    expect(cover?.id, 'taken');
  });

  test(
    'an album-only photo still works as the cover, by default or chosen',
    () {
      expect(
        TripShareCardCache.resolveCoverPhoto(_summary(), [album])?.id,
        'album',
      );
      expect(
        TripShareCardCache.resolveCoverPhoto(_summary(coverMediaId: 'album'), [
          taken,
          album,
        ])?.id,
        'album',
      );
      expect(
        TripShareCardCache.resolveCoverPhoto(_summary(), const []),
        isNull,
      );
    },
  );
}
