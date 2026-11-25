import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../domain/plan_day.dart';

/// "Start Day 2?" (design 7a): the day's stops in order, before the Trip
/// starts recording and directions open. True when confirmed.
Future<bool> showStartDayConfirm(
  BuildContext context,
  PlanDay day, {
  bool recordedBefore = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          recordedBefore
              ? 'Record ${day.displayTitle} again?'
              : 'Start ${day.displayTitle}?',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Trip is recorded and directions open in Maps. '
                'Badges come from where you actually go.',
                style: AppTypeScale.small,
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < day.stops.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${i + 1}. ${day.stops[i].place.name}'),
                ),
              if (day.stops.length > 9)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Maps shows the first 9 stops on the way. The Trip still '
                    'records every stop.',
                    style: AppTypeScale.meta,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start trip'),
          ),
        ],
      ),
    ) ??
    false;
