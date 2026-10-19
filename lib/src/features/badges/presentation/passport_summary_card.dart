import 'package:flutter/material.dart';

import '../domain/passport_book.dart';
import '../domain/passport_level.dart';
import '../../../design/app_colors.dart';
import 'passport_card_shell.dart';
import 'passport_dates.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// The traveller's card at the top of the landing, on the pale blue wash:
/// who they are, when their first stamp was, how many of the 47
/// counties are stamped, a bar with one segment per county, and a legend.
class PassportSummaryCard extends StatelessWidget {
  const PassportSummaryCard({
    super.key,
    required this.book,
    this.holderName,
  });

  final PassportBook book;

  /// The traveller's name, once it has loaded.
  final String? holderName;

  @override
  Widget build(BuildContext context) {
    final levels = book.barLevels;
    final name = holderName?.trim();
    final first = book.firstStampAt;
    const soft = AppColors.mutedForeground;
    return PassportCardShell(
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOLDER',
                      style: passportText(
                        10,
                        weight: FontWeight.w600,
                        color: soft,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name == null || name.isEmpty ? 'Traveller' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: passportText(
                        19,
                        weight: FontWeight.w700,
                        color: PassportInk.primary,
                        height: 1.2,
                      ),
                    ),
                    if (first != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'First stamp ${passportDate(first)}',
                        style: passportText(12.5, color: soft),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '${book.claimedCount}',
                      style: passportText(
                        44,
                        weight: FontWeight.w700,
                        color: AppColors.accent,
                        height: 1,
                      ),
                      children: [
                        TextSpan(
                          text: '/${book.total}',
                          style: passportText(
                            22,
                            weight: FontWeight.w500,
                            color: soft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'COUNTIES EXPLORED',
                    style: passportText(
                      9.5,
                      weight: FontWeight.w600,
                      color: soft,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stamped counties stand tall in their level's colour, the rest
          // sit low and pale, bottom-aligned.
          SizedBox(
            height: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < levels.length; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    child: Container(
                      height: levels[i] == PassportLevel.none ? 13 : 20,
                      decoration: BoxDecoration(
                        color: levels[i] == PassportLevel.none
                            ? AppColors.trackInactive
                            : levels[i].ring,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final level in PassportLevel.values.reversed)
                if (level != PassportLevel.none && book.countAt(level) > 0)
                  _LegendItem(level: level, count: book.countAt(level)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.level, required this.count});

  final PassportLevel level;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: level.ring,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count ${level.label}',
          style: passportText(
            11.5,
            weight: FontWeight.w500,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
