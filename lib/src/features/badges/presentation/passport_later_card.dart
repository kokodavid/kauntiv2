import 'package:flutter/material.dart';

import '../domain/passport_county.dart';
import '../domain/passport_level.dart';
import '../domain/passport_progress.dart';
import 'passport_milestone_rows.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// A metal stamp that can't be earned yet because check-ins are switched
/// off: milestones dimmed, LATER tag.
class PassportLaterCard extends StatelessWidget {
  const PassportLaterCard._({
    required this.tag,
    required this.hint,
    required this.title,
    required this.body,
    required this.next,
    required this.progress,
  });

  /// Check-ins are off for everyone.
  factory PassportLaterCard.later({
    required PassportCounty county,
    required PassportLevel next,
    required PassportProgress progress,
  }) => PassportLaterCard._(
    tag: 'LATER',
    hint: '${next.label} is coming',
    title: 'Bronze, Silver and Gold come with place verification',
    body:
        "You'll earn them by visiting real places in ${county.name}. Your "
        'Explored stamp stays as it is, and nothing you have earned goes '
        'away.',
    next: next,
    progress: progress,
  );

  final String tag;
  final String hint;
  final String title;
  final String body;
  final PassportLevel next;
  final PassportProgress progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PassportInk.disabled),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PassportInk.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: passportText(
                    10,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hint,
                style: passportText(
                  12,
                  weight: FontWeight.w600,
                  color: PassportInk.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: passportText(15, weight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: passportText(
              12.5,
              color: PassportInk.secondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          PassportMilestoneRows(rows: progress.rows, next: next, dimmed: true),
        ],
      ),
    );
  }
}
