import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_native_ad_card.dart';
import '../../ads/application/ads_providers.dart';

/// One ad on a county's Passport page, just above the Explore card. Extra
/// space below keeps it clear of the card so a tap on one can't land on the
/// other. Renders nothing unless ads are on for this user.
class PassportAdSlot extends ConsumerWidget {
  const PassportAdSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(nativeAdUnitProvider);
    if (unit == null || !ref.watch(showAdsProvider)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppNativeAdCard(adUnitId: unit),
    );
  }
}
