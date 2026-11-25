part of 'passport_share_card.dart';

/// Levels in the order the legend lists them, highest first.
const _legendLevels = [
  PassportLevel.gold,
  PassportLevel.silver,
  PassportLevel.bronze,
  PassportLevel.explored,
  PassportLevel.passedThrough,
];

/// One row per level the traveller has (count, colour, name), each on a
/// single line; levels with nothing are left out.
class _Legend extends StatelessWidget {
  const _Legend({required this.book, this.onPhoto = false});

  final PassportBook book;
  final bool onPhoto;

  static String _label(PassportLevel level) =>
      level == PassportLevel.passedThrough ? 'Passed through' : level.label;

  Color _swatch(PassportLevel level) =>
      onPhoto && level == PassportLevel.passedThrough
      ? const Color(0xFFD4D4D8)
      : level.ring;

  @override
  Widget build(BuildContext context) {
    final count = onPhoto ? Colors.white : PassportInk.primary;
    final label = onPhoto ? const Color(0xCCFFFFFF) : PassportInk.secondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final level in _legendLevels)
          if (book.countAt(level) case final n when n > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _swatch(level),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$n',
                    style: passportText(
                      13,
                      weight: FontWeight.w700,
                      color: count,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _label(level),
                    maxLines: 1,
                    softWrap: false,
                    style: passportText(13, color: label),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// "LATEST STAMP · Nakuru · Bronze" with the county's stamp art (or its
/// medallion while it has none). Nothing when no stamp is dated.
class _LatestStamp extends StatelessWidget {
  const _LatestStamp({required this.county});

  final PassportCounty county;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.78),
      border: Border.all(color: PassportInk.track),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 44,
          child: PassportStampArt.has(county)
              ? PassportStampArt(county: county, extent: 44)
              : Center(
                  child: PassportMedallion(
                    county: county.county,
                    level: county.level,
                    size: 34,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LATEST STAMP',
                style: passportText(
                  9.5,
                  weight: FontWeight.w600,
                  color: PassportInk.tertiary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  text: county.name,
                  style: passportText(14, weight: FontWeight.w700),
                  children: [
                    TextSpan(
                      text: ' · ${county.level.label}',
                      style: passportText(
                        12,
                        weight: FontWeight.w600,
                        color: county.level.text,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// The bottom line: the @username small and quiet on the left (left out
/// when it's turned off), kaunti47.com in the right-hand corner.
class _Footer extends StatelessWidget {
  const _Footer({required this.username, required this.onPhoto});

  final String? username;
  final bool onPhoto;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: username == null
            ? const SizedBox.shrink()
            : Text(
                '@$username',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: passportText(
                  11,
                  weight: FontWeight.w500,
                  color: onPhoto
                      ? const Color(0xB3FFFFFF)
                      : PassportInk.tertiary,
                ),
              ),
      ),
      const SizedBox(width: 12),
      Text(
        'kaunti47.com',
        style: passportText(
          12,
          weight: FontWeight.w600,
          color: onPhoto ? Colors.white : PassportInk.blueDeep,
        ),
      ),
    ],
  );
}

/// The "MY PASSPORT" label at the top right, the same words on both
/// styles; only its colours change over a photo.
class _Pill extends StatelessWidget {
  const _Pill({required this.onPhoto});

  final bool onPhoto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: onPhoto
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.75),
      border: Border.all(
        color: onPhoto
            ? Colors.white.withValues(alpha: 0.22)
            : const Color(0xFFDCE7F3),
      ),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      'MY PASSPORT',
      style: passportText(
        10.5,
        weight: FontWeight.w600,
        color: onPhoto ? Colors.white : PassportInk.blueDeep,
        letterSpacing: 1.3,
      ),
    ),
  );
}
