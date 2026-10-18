import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/place_photos/domain/photo_submission.dart';

void main() {
  test('server error text maps to a code and a sentence', () {
    final f = PhotoSubmitFailure.fromServer('daily_limit ');
    expect(f.code, 'daily_limit');
    expect(f.message, contains('24 hours'));
  });

  test('unknown error gets the generic sentence', () {
    final f = PhotoSubmitFailure.fromServer('boom');
    expect(f.code, 'unknown');
    expect(f.message, contains('Try again'));
  });

  test('a row becomes a submission', () {
    final s = PhotoSubmission.fromRow({
      'id': 'a',
      'place_id': 'p',
      'status': 'rejected',
      'reject_reason': 'Blurry',
      'created_at': '2026-10-20T10:00:00Z',
    });
    expect(s.status, PhotoSubmissionStatus.rejected);
    expect(s.rejectReason, 'Blurry');
  });
}
