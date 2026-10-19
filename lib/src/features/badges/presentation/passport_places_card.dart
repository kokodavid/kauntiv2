import 'package:flutter/material.dart';

import '../../../core/domain/place_type.dart';
import '../../../core/widgets/app_network_image.dart';
import '../domain/passport_progress.dart';
import 'passport_dates.dart';
import 'passport_palette.dart';
import 'passport_text.dart';

/// Places the user was verified at in this county. Saved or ticked places
/// never appear here; the card is hidden until there is one.
class PassportPlacesCard extends StatelessWidget {
  const PassportPlacesCard({
    super.key,
    required this.places,
    required this.total,
  });

  final List<VerifiedPlace> places;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Places discovered',
                  style: passportText(15, weight: FontWeight.w700),
                ),
              ),
              Text(
                '${places.length} of $total on file',
                style: passportText(12, color: PassportInk.tertiary),
              ),
            ],
          ),
          for (final place in places)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: PassportInk.rule)),
              ),
              child: Row(
                children: [
                  _Thumb(url: place.thumbnailUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: passportText(13.5, weight: FontWeight.w600),
                        ),
                        Text(
                          '${PlaceType.of(place.category).label} · '
                          '${passportDate(place.visitedAt)}',
                          style: passportText(12, color: PassportInk.tertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The place's photo with a small tick on it (the proof it was visited), or
/// a blue tick tile when the place has no photo or it can't load.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String? url;

  static const _size = 52.0;
  static const _blue = Color(0xFF0A84FF);

  Widget get _fallback => Container(
    width: _size,
    height: _size,
    decoration: BoxDecoration(
      color: _blue,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
  );

  @override
  Widget build(BuildContext context) {
    final photo = url;
    if (photo == null || photo.isEmpty) return _fallback;
    return SizedBox.square(
      dimension: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
              image: appNetworkImage(photo, cacheWidth: 160),
              width: _size,
              height: _size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback,
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}
