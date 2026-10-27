import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_banner_ad_card.dart';
import '../../../core/widgets/app_native_ad_card.dart';
import '../../ads/application/ads_providers.dart';

/// One ad between Explore rows, with the same 10 px gap the rows use. Lists
/// pass [banner] for a short adaptive banner; a screen where the ad stands
/// alone keeps the medium native ad. Renders nothing unless ads are on for
/// this user.
class ExploreAdSlot extends ConsumerWidget {
  const ExploreAdSlot({super.key, this.banner = false});

  final bool banner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(banner ? bannerAdUnitProvider : nativeAdUnitProvider);
    if (unit == null || !ref.watch(showAdsProvider)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: banner
          ? AppBannerAdCard(adUnitId: unit)
          : AppNativeAdCard(adUnitId: unit),
    );
  }
}
