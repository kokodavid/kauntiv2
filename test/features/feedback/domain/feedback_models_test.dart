import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/feedback/domain/feedback_models.dart';

void main() {
  test('unknown keys fall back to a safe default', () {
    expect(FeedbackStatus.fromKey('nope'), FeedbackStatus.received);
    expect(FeedbackCategory.fromKey(null), FeedbackCategory.bug);
    expect(FeedbackSeverity.fromKey('x'), FeedbackSeverity.minor);
    expect(FeedbackStatus.fromKey('duplicate'), FeedbackStatus.duplicate);
  });

  test('only unfinished statuses count as open', () {
    expect(FeedbackStatus.received.isOpen, isTrue);
    expect(FeedbackStatus.planned.isOpen, isTrue);
    expect(FeedbackStatus.resolved.isOpen, isFalse);
    expect(FeedbackStatus.rejected.isOpen, isFalse);
    expect(FeedbackStatus.duplicate.isOpen, isFalse);
  });

  test('title and description lengths follow the database limits', () {
    expect(FeedbackDraft.titleOk('ab'), isFalse);
    expect(FeedbackDraft.titleOk('  abc  '), isTrue);
    expect(FeedbackDraft.titleOk('a' * 121), isFalse);
    expect(FeedbackDraft.descriptionOk('too short'), isFalse);
    expect(FeedbackDraft.descriptionOk('long enough text'), isTrue);
    expect(FeedbackDraft.descriptionOk('a' * 4001), isFalse);
  });

  test('files are typed by extension and anything else is refused', () {
    expect(FeedbackAttachmentFile.mimeForPath('/a/shot.JPG'), 'image/jpeg');
    expect(FeedbackAttachmentFile.mimeForPath('/a/shot.png'), 'image/png');
    expect(FeedbackAttachmentFile.mimeForPath('/a/clip.mov'), 'video/quicktime');
    expect(FeedbackAttachmentFile.mimeForPath('/a/clip.mp4'), 'video/mp4');
    expect(FeedbackAttachmentFile.mimeForPath('/a/doc.pdf'), isNull);
    expect(FeedbackAttachmentFile.mimeForPath('/a/noextension'), isNull);
  });

  test('client ids are version 4 uuids', () {
    final id = FeedbackDraft.newClientId(Random(1));
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(id),
      isTrue,
      reason: id,
    );
    expect(FeedbackDraft.newClientId(Random(2)), isNot(id));
  });

  test('a queued submission has no receipt', () {
    const queued = FeedbackSubmission.queued();
    expect(queued.queued, isTrue);
    expect(queued.receipt, isNull);
    const sent = FeedbackSubmission.sent(
      FeedbackReceipt(id: 'x', reference: 'FB-0001'),
      filesNotSent: 1,
    );
    expect(sent.queued, isFalse);
    expect(sent.receipt!.reference, 'FB-0001');
  });
}
