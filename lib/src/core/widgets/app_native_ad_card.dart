import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../design/app_colors.dart';

/// One native (in-feed) ad on Google's medium template, whose media view is
/// big enough for video (the small template fails AdMob's validator). Callers decide
/// whether an ad may show at all (the ads feature's `showAdsProvider`) and
/// pass the unit; this widget only loads and draws it.
///
/// It reserves its height while the ad loads so a list below does not jump,
/// and collapses to nothing if the ad fails to load.
class AppNativeAdCard extends StatefulWidget {
  const AppNativeAdCard({
    super.key,
    required this.adUnitId,
    this.height = 360,
  });

  final String adUnitId;

  /// Room reserved for the medium template (its media view fits video).
  final double height;

  @override
  State<AppNativeAdCard> createState() => _AppNativeAdCardState();
}

class _AppNativeAdCardState extends State<AppNativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _ad = NativeAd(
      adUnitId: widget.adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: AppColors.secondaryFill,
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          unawaited(ad.dispose());
          if (mounted) setState(() => _failed = true);
        },
      ),
    );
    unawaited(_ad!.load());
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: widget.height,
          color: AppColors.secondaryFill,
          child: _loaded ? AdWidget(ad: ad) : null,
        ),
      ),
    );
  }
}
