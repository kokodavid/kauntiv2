import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../design/app_colors.dart';

/// One inline adaptive banner for list screens: short (at most 100 px), no
/// video, sized to the screen width minus the lists' 16 px side padding.
/// Reserves its height while loading and collapses if the ad fails.
class AppBannerAdCard extends StatefulWidget {
  const AppBannerAdCard({super.key, required this.adUnitId});

  final String adUnitId;

  @override
  State<AppBannerAdCard> createState() => _AppBannerAdCardState();
}

class _AppBannerAdCardState extends State<AppBannerAdCard> {
  static const _maxHeight = 100;

  BannerAd? _ad;
  double _height = 60;
  bool _loaded = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ad != null) return;
    final width = (MediaQuery.sizeOf(context).width - 32).truncate();
    final ad = BannerAd(
      adUnitId: widget.adUnitId,
      size: AdSize.getInlineAdaptiveBannerAdSize(width, _maxHeight),
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => unawaited(_onLoaded(ad as BannerAd)),
        onAdFailedToLoad: (ad, _) {
          unawaited(ad.dispose());
          if (mounted) setState(() => _failed = true);
        },
      ),
    );
    _ad = ad;
    unawaited(ad.load());
  }

  Future<void> _onLoaded(BannerAd ad) async {
    final size = await ad.getPlatformAdSize();
    if (!mounted) return;
    setState(() {
      _loaded = true;
      if (size != null && size.height > 0) _height = size.height.toDouble();
    });
  }

  @override
  void dispose() {
    final ad = _ad;
    if (ad != null) unawaited(ad.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (_failed || ad == null) return const SizedBox.shrink();
    return Semantics(
      label: 'Advertisement',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: _height,
          color: AppColors.secondaryFill,
          child: _loaded ? AdWidget(ad: ad) : null,
        ),
      ),
    );
  }
}
