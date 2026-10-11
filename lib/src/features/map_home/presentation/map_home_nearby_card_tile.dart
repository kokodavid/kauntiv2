import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_county_shape.dart';
import '../domain/map_home_nearby_cards.dart';

/// One card of the collapsed sheet's carousel: a photo with a kind pill and
/// the distance on top, the name and a go arrow along the bottom.
class MapHomeNearbyCardTile extends StatelessWidget {
  const MapHomeNearbyCardTile({super.key, required this.card, this.onTap});

  final MapHomeNearbyCard card;
  final VoidCallback? onTap;

  static const width = 264.0;
  static const height = 116.0;

  @override
  Widget build(BuildContext context) {
    final dot = switch (card.kind) {
      MapHomeNearbyKind.place => AppColors.accent,
      MapHomeNearbyKind.newCounty => AppColors.legendHome,
    };
    return Semantics(
      button: true,
      label: '${card.title}, ${card.pill}, ${card.subtitle}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                color: Color(0x14101828),
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Photo(card: card),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, 0.4, 1],
                        colors: [
                          Color(0x59000000),
                          Color(0x00000000),
                          Color(0xC7000000),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Pill(label: card.pill, dot: dot),
                        _Distance(card: card),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 12,
                    bottom: 11,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTypeScale.family,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                card.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTypeScale.family,
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.card});

  final MapHomeNearbyCard card;

  @override
  Widget build(BuildContext context) {
    final url = card.imageUrl;
    final fallback = ColoredBox(
      color: const Color(0xFF2A2D33),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: AppCountyShape(
          county: card.county,
          fill: Colors.transparent,
          stroke: Colors.white24,
          strokeWidth: 2,
          dashed: true,
        ),
      ),
    );
    if (url == null) return fallback;
    return Image(
      image: appNetworkImage(url),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.dot});

  final String label;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 9, 4),
          color: const Color(0x800F1114),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTypeScale.family,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Distance extends StatelessWidget {
  const _Distance({required this.card});

  final MapHomeNearbyCard card;

  @override
  Widget build(BuildContext context) {
    final value = card.distanceValue;
    if (value == null) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(
        text: value,
        children: [
          TextSpan(
            text: ' ${card.distanceUnit}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      style: const TextStyle(
        fontFamily: AppTypeScale.family,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        shadows: [Shadow(color: Color(0x66000000), blurRadius: 6)],
      ),
    );
  }
}
