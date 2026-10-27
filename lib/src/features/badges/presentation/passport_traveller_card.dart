import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../profile/application/public_profile_providers.dart';
import '../domain/passport_book.dart';
import '../domain/passport_level.dart';
import 'passport_card_side_panel.dart';
import 'passport_dates.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// The traveller card at the top of the Passport: holder, first stamp, the
/// count, a bar with one segment per county and a Kenya map of what is
/// stamped. The faint background art is a single asset, so it can be
/// swapped without touching the layout; without it the card still reads.
class PassportTravellerCard extends ConsumerStatefulWidget {
  const PassportTravellerCard({super.key, required this.book, this.holderName});

  /// Drop the artwork here (a wide JPG; it fills the card).
  static const artAsset = 'assets/images/passport_card_art.jpg';

  final PassportBook book;
  final String? holderName;

  @override
  ConsumerState<PassportTravellerCard> createState() =>
      _PassportTravellerCardState();
}

class _PassportTravellerCardState extends ConsumerState<PassportTravellerCard> {
  /// The right-hand panel shows the Kenya map, or the holder's picture.
  bool _showPhoto = false;

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final avatarUrl = ref.watch(
      myPublicProfileProvider.select((p) => p.value?.avatarUrl),
    );
    final name = widget.holderName?.trim();
    final first = book.firstStampAt;
    final levels = book.barLevels;
    return Semantics(
      container: true,
      label:
          '${book.claimedCount} of ${book.total} counties explored'
          '${first == null ? '' : ', first stamp ${passportDate(first)}'}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.lockedFill),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEAF3FC), Color(0xFFF4F8FC), Color(0xFFF8F1EA)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: Image.asset(
                    PassportTravellerCard.artAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
              // A soft wash on the text side keeps the name and count
              // readable over the fine line work.
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xCCFFFFFF), Color(0x00FFFFFF)],
                      stops: [0, 0.75],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 11,
                          child: _Holder(
                            name: name,
                            first: first,
                            claimed: book.claimedCount,
                            total: book.total,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 8,
                          child: PassportCardSidePanel(
                            showPhoto: _showPhoto,
                            avatarUrl: avatarUrl,
                            name: name,
                            levels: {
                              for (final c in book.counties) c.code: c.level,
                            },
                            onToggle: () =>
                                setState(() => _showPhoto = !_showPhoto),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _Bar(levels: levels),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Holder extends StatelessWidget {
  const _Holder({
    required this.name,
    required this.first,
    required this.claimed,
    required this.total,
  });

  final String? name;
  final DateTime? first;
  final int claimed;
  final int total;

  @override
  Widget build(BuildContext context) {
    const soft = AppColors.mutedForeground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRAVELLER',
          style: passportText(
            10.5,
            weight: FontWeight.w600,
            color: soft,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name == null || name!.isEmpty ? 'Traveller' : name!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: passportText(
            22,
            weight: FontWeight.w700,
            color: PassportInk.primary,
            height: 1.15,
          ),
        ),
        if (first != null) ...[
          const SizedBox(height: 6),
          Text(
            'First stamp ${passportDate(first!)}',
            style: passportText(13, color: PassportInk.secondary),
          ),
        ],
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            text: '$claimed',
            style: passportText(
              40,
              weight: FontWeight.w700,
              color: AppColors.accent,
              height: 1,
            ),
            children: [
              TextSpan(
                text: ' / $total',
                style: passportText(22, weight: FontWeight.w500, color: soft),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'COUNTIES EXPLORED',
          style: passportText(
            10,
            weight: FontWeight.w600,
            color: soft,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.levels});

  final List<PassportLevel> levels;

  @override
  Widget build(BuildContext context) {
    // Stamped counties stand tall in their level's colour, the rest sit low
    // and pale, bottom-aligned.
    return SizedBox(
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
    );
  }
}
