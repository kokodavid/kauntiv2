import 'package:flutter/material.dart';

import '../../../core/widgets/county_badge_medallion.dart';
import '../../../widgets/app_icon_badge.dart';
import '../domain/passport_book.dart';
import '../domain/passport_level.dart';
import 'passport_cover_palette.dart';
import 'passport_cover_stamps.dart';
import 'passport_text.dart';

/// The Passport's cover, shown the first time the tab opens each app
/// session: navy with gold ink, the app icon in a double gold ring, the
/// traveller's name and count, and one button. A brand-new traveller sees
/// previews of the stamps they will collect; others see their latest.
class PassportCover extends StatelessWidget {
  const PassportCover({
    super.key,
    required this.book,
    required this.onOpen,
    this.holderName,
  });

  final PassportBook book;
  final VoidCallback onOpen;

  /// The traveller's name, once it has loaded.
  final String? holderName;

  /// What the line under the count says. Only what is true today: the one
  /// next step that exists is turning a pass into Explored.
  String get _body {
    final next = book.nextStamp();
    final county = next.county;
    if (!next.isFirst &&
        county != null &&
        next.level == PassportLevel.explored) {
      return 'Spend two hours in ${county.name} to earn Explored. '
          'Time counts on its own.';
    }
    return 'Every county has its own page. Open the passport to see your '
        'stamps and what comes next.';
  }

  @override
  Widget build(BuildContext context) {
    final returning = book.stampedCount > 0;
    final name = holderName?.trim();
    // The most advanced stamps first, for the three on the cover.
    final shown = ([...book.counties.where((c) => c.isStamped)]
          ..sort((a, b) => b.level.index.compareTo(a.level.index)))
        .take(3)
        .toList();
    const sizes = [54.0, 64.0, 54.0];
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: PassportCoverPalette.gradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 40, 30, 28),
          child: Column(
            children: [
              const _Seal(),
              const SizedBox(height: 26),
              Text(
                'COUNTY PASSPORT',
                style: passportText(
                  12,
                  weight: FontWeight.w700,
                  color: PassportCoverPalette.gold,
                  letterSpacing: 3.1,
                ),
              ),
              if (name != null && name.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: passportText(
                    13,
                    weight: FontWeight.w500,
                    color: PassportCoverPalette.softText,
                  ),
                ),
              ],
              SizedBox(height: returning ? 36 : 56),
              if (returning) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < shown.length; i++)
                      Transform.translate(
                        offset: Offset(
                          i == 0 ? 8.0 : (i == 2 ? -8.0 : 0.0),
                          0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: PassportCoverPalette.navy,
                            border: Border.all(
                              color: PassportCoverPalette.gold,
                              width: 1.5,
                            ),
                          ),
                          child: CountyBadgeMedallion(
                            county: shown[i].county,
                            earned:
                                shown[i].level.index >=
                                PassportLevel.explored.index,
                            size: sizes[i],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              Text(
                returning
                    ? '${book.claimedCount} of ${book.total} counties explored'
                    : '${book.total} pages, waiting\nfor their first stamp',
                textAlign: TextAlign.center,
                style: passportText(
                  returning ? 23 : 25,
                  weight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  returning
                      ? _body
                      : 'Travel into any county and Kaunti47 presses the '
                            "first stamp for you. There's nothing to tap.",
                  textAlign: TextAlign.center,
                  style: passportText(
                    14,
                    color: PassportCoverPalette.softText,
                    height: 1.55,
                  ),
                ),
              ),
              const Spacer(),
              if (!returning) ...[
                const PassportCoverStamps(),
                const SizedBox(height: 28),
              ],
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: PassportCoverPalette.navy,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: onOpen,
                  child: Text(
                    'Open passport',
                    style: passportText(
                      16,
                      weight: FontWeight.w600,
                      color: PassportCoverPalette.navy,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The app icon inside two gold rings, like a seal.
class _Seal extends StatelessWidget {
  const _Seal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: PassportCoverPalette.gold, width: 1.5),
      ),
      child: Container(
        width: 82,
        height: 82,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: PassportCoverPalette.gold.withValues(alpha: 0.6),
          ),
        ),
        child: const AppIconBadge(size: 50),
      ),
    );
  }
}
